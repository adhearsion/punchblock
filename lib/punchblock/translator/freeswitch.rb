# encoding: utf-8

require 'celluloid'
require 'ruby_fs'

module Punchblock
  module Translator
    class Freeswitch
      include Celluloid
      include HasGuardedHandlers

      extend ActiveSupport::Autoload

      autoload :Call
      autoload :Component

      attr_reader :connection, :calls

      trap_exit :actor_died

      def initialize(connection)
        pb_logger.debug "Starting up..."
        @connection = connection
        @calls, @components, @platform_id_to_call_id = {}, {}, {}
        setup_handlers
      end

      def register_call(call)
        @platform_id_to_call_id[call.platform_id] = call.id
        @calls[call.id] ||= call
      end

      def deregister_call(call)
        @platform_id_to_call_id.delete call.platform_id
        @calls.delete call.id
      end

      def call_with_id(call_id)
        @calls[call_id]
      end

      def call_for_platform_id(platform_id)
        call_with_id @platform_id_to_call_id[platform_id]
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
          pb_logger.info "A channel was parked. Creating a new call."
          call = Call.new event[:unique_id], current_actor, Call.es_env_variables(event.content), stream
          link call
          register_call call
          call.send_offer!
        end

        register_handler :es, lambda { |event| es_event_known_call? event } do |event|
          call = call_for_platform_id event[:unique_id]
          call.handle_es_event! event
        end
      end

      def stream
        connection.stream
      end

      def shutdown
        pb_logger.debug "Shutting down"
        @calls.values.each(&:shutdown)
        terminate
      end

      def handle_es_event(event)
        exclusive do
          pb_logger.trace "Received event #{event.inspect}"
          trigger_handler :es, event
        end
      end

      # def handle_ami_event(event)
      #   exclusive do
      #     unless ami_event_known_call?(event)
      #       handle_pb_event Event::Asterisk::AMI::Event.new(:name => event.name, :attributes => event.headers)
      #     end
      #   end
      # end

      def handle_pb_event(event)
        connection.handle_event event
      end

      def execute_command(command, options = {})
        pb_logger.trace "Executing command #{command.inspect}"
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
          call.execute_command! command
        else
          command.response = ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{command.target_call_id}", command.target_call_id
        end
      end

      def execute_component_command(command)
        if (component = component_with_id(command.component_id))
          component.execute_command! command
        else
          command.response = ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id}", command.target_call_id, command.component_id
        end
      end

      def execute_global_command(command)
        case command
      #   when Punchblock::Component::Asterisk::AMI::Action
      #     component = Component::Asterisk::AMIAction.new command, current_actor
      #     register_component component
      #     component.execute!
        when Punchblock::Command::Dial
          call = Call.new_link command.to, current_actor, nil, stream
          register_call call
          call.dial! command
        else
          command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command"
        end
      end

      def actor_died(actor, reason)
        return unless reason
        pb_logger.error "A linked actor (#{actor.inspect}) died due to #{reason.inspect}"
        if id = @calls.key(actor)
          pb_logger.info "Dead actor was a call we know about, with ID #{id}. Removing it from the registry..."
          @calls.delete id
          end_event = Punchblock::Event::End.new :target_call_id  => id,
                                                 :reason          => :error
          handle_pb_event end_event
        end
      end

      private

      def es_event_known_call?(event)
        event[:unique_id] && call_for_platform_id(event[:unique_id])
      end
    end
  end
end
