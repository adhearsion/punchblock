# encoding: utf-8

require 'celluloid'
require 'ruby_fs'

module Punchblock
  module Translator
    class Freeswitch
      include Celluloid
      include HasGuardedHandlers
      include DeadActorSafety

      extend ActorHasGuardedHandlers
      execute_guarded_handlers_on_receiver

      extend ActiveSupport::Autoload

      autoload :Call
      autoload :Component

      attr_reader :connection, :calls

      trap_exit :actor_died

      finalizer :finalize

      def initialize(connection)
        @connection = connection
        @calls, @components = {}, {}
        setup_handlers
      end

      def register_call(call)
        @calls[call.id] ||= call
      end

      def deregister_call(id)
        @calls.delete id
      end

      def call_with_id(call_id)
        @calls[call_id]
      end

      def register_component(component)
        @components[component.id] ||= component
      end

      def component_with_id(component_id)
        @components[component_id]
      end

      def setup_handlers
        register_handler :es, RubyFS::Stream::Connected do
          handle_pb_event Connection::Connected.new
          throw :halt
        end

        register_handler :es, RubyFS::Stream::Disconnected do
          throw :halt
        end

        register_handler :es, :event_name => 'CHANNEL_PARK' do |event|
          throw :pass if es_event_known_call? event
          call = Call.new event[:unique_id], current_actor, event.content.select { |k,v| k.to_s =~ /variable/ }, stream
          link call
          register_call call
          call.async.send_offer
        end

        register_handler :es, :event_name => ['CHANNEL_BRIDGE', 'CHANNEL_UNBRIDGE'], [:has_key?, :other_leg_unique_id] => true do |event|
          call = call_with_id event[:other_leg_unique_id]
          call.async.handle_es_event event if call
          throw :pass
        end

        register_handler :es, lambda { |event| es_event_known_call? event } do |event|
          call = call_with_id event[:unique_id]
          call.async.handle_es_event event
        end
      end

      def stream
        connection.stream
      end

      def finalize
        @calls.values.each do |call|
          safe_from_dead_actors do
            call.terminate
          end
        end
      end

      def handle_es_event(event)
        trigger_handler :es, event
      end
      exclusive :handle_es_event

      def handle_pb_event(event)
        connection.handle_event event
      end

      def execute_command(command, options = {})
        command.request!

        command.target_call_id ||= options[:call_id]
        command.component_id ||= options[:component_id]

        if command.target_call_id
          execute_call_command command
        elsif command.component_id
          execute_component_command command
        else
          execute_global_command command
        end
      end

      def execute_call_command(command)
        if call = call_with_id(command.target_call_id)
          call.async.execute_command command
        else
          command.response = ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{command.target_call_id}", command.target_call_id
        end
      end

      def execute_component_command(command)
        if (component = component_with_id(command.component_id))
          component.async.execute_command command
        else
          command.response = ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id}", command.target_call_id, command.component_id
        end
      end

      def execute_global_command(command)
        case command
        when Punchblock::Command::Dial
          call = Call.new_link Punchblock.new_uuid, current_actor, nil, stream
          register_call call
          call.async.dial command
        else
          command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command"
        end
      end

      def actor_died(actor, reason)
        return unless reason
        pb_logger.error "A linked actor (#{actor.inspect}) died due to #{reason.inspect}"
        if id = @calls.key(actor)
          @calls.delete id
          end_event = Punchblock::Event::End.new :target_call_id  => id,
                                                 :reason          => :error
          handle_pb_event end_event
        end
      end

      private

      def es_event_known_call?(event)
        event[:unique_id] && call_with_id(event[:unique_id])
      end
    end
  end
end
