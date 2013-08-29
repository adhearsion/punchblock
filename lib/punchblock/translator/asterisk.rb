# encoding: utf-8

require 'celluloid'
require 'ruby_ami'

module Punchblock
  module Translator
    class Asterisk
      include Celluloid

      # Indicates that a command was executed against a channel which no longer exists
      ChannelGoneError = Class.new Punchblock::Error

      extend ActiveSupport::Autoload

      autoload :AGICommand
      autoload :Call
      autoload :Channel
      autoload :Component

      attr_reader :ami_client, :connection, :calls

      REDIRECT_CONTEXT = 'adhearsion-redirect'
      REDIRECT_EXTENSION = '1'
      REDIRECT_PRIORITY = '1'

      EVENTS_ALLOWED_BRIDGED = %w{AGIExec AsyncAGI}

      trap_exit :actor_died

      def initialize(ami_client, connection)
        @ami_client, @connection = ami_client, connection
        @calls, @components, @channel_to_call_id = {}, {}, {}
      end

      def register_call(call)
        @channel_to_call_id[call.channel] = call.id
        @calls[call.id] ||= call
      end

      def deregister_call(id, channel)
        @channel_to_call_id.delete channel
        @calls.delete id
      end

      def call_with_id(call_id)
        @calls[call_id]
      end

      def call_for_channel(channel)
        call_with_id @channel_to_call_id[Channel.new(channel).name]
      end

      def register_component(component)
        @components[component.id] ||= component
      end

      def component_with_id(component_id)
        @components[component_id]
      end

      def shutdown
        @calls.values.each { |call| call.async.shutdown }
        terminate
      end

      def handle_ami_event(event)
        return unless event.is_a? RubyAMI::Event

        if event.name == 'FullyBooted'
          handle_pb_event Connection::Connected.new
          run_at_fully_booted
          return
        end

        handle_varset_ami_event event

        ami_dispatch_to_or_create_call event

        unless ami_event_known_call?(event)
          handle_pb_event Event::Asterisk::AMI::Event.new(name: event.name, headers: event.headers)
        end
      end
      exclusive :handle_ami_event

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
        when Punchblock::Component::Asterisk::AMI::Action
          component = Component::Asterisk::AMIAction.new command, current_actor, ami_client
          register_component component
          component.async.execute
        when Punchblock::Command::Dial
          call = Call.new_link command.to, current_actor, ami_client, connection
          register_call call
          call.async.dial command
        else
          command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command"
        end
      end

      def run_at_fully_booted
        send_ami_action 'Command', 'Command' => "dialplan add extension #{REDIRECT_EXTENSION},#{REDIRECT_PRIORITY},AGI,agi:async into #{REDIRECT_CONTEXT}"

        result = send_ami_action 'Command', 'Command' => "dialplan show #{REDIRECT_CONTEXT}"
        if result.text_body =~ /failed/
          pb_logger.error "Punchblock failed to add the #{REDIRECT_EXTENSION} extension to the #{REDIRECT_CONTEXT} context. Please add a [#{REDIRECT_CONTEXT}] entry to your dialplan."
        end

        check_recording_directory
      end

      def check_recording_directory
        pb_logger.warn "Recordings directory #{Component::Record::RECORDING_BASE_PATH} does not exist. Recording might not work. This warning can be ignored if Adhearsion is running on a separate machine than Asterisk. See http://adhearsion.com/docs/call-controllers#recording" unless File.exists?(Component::Record::RECORDING_BASE_PATH)
      end

      def actor_died(actor, reason)
        return unless reason
        if id = @calls.key(actor)
          @calls.delete id
          end_event = Punchblock::Event::End.new :target_call_id  => id,
                                                 :reason          => :error
          handle_pb_event end_event
        end
      end

      private

      def send_ami_action(name, headers = {})
        ami_client.send_action name, headers
      end

      def handle_varset_ami_event(event)
        return unless event.name == 'VarSet' && event['Variable'] == 'punchblock_call_id' && (call = call_with_id event['Value'])

        @channel_to_call_id.delete call.channel
        call.channel = event['Channel']
        register_call call
      end

      def ami_dispatch_to_or_create_call(event)
        calls_for_event = channels_for_ami_event(event).inject({}) do |h, channel|
          call = call_for_channel channel
          h[channel] = call if call
          h
        end

        if !calls_for_event.empty?
          calls_for_event.each_pair do |channel, call|
            next if channel.bridged? && !EVENTS_ALLOWED_BRIDGED.include?(event.name)
            call.async.process_ami_event event
          end
        elsif event.name == "AsyncAGI" && event['SubEvent'] == "Start"
          handle_async_agi_start_event event
        end
      end

      def channels_for_ami_event(event)
        [event['Channel'], event['Channel1'], event['Channel2']].compact.map { |channel| Channel.new(channel) }
      end

      def ami_event_known_call?(event)
        (event['Channel'] && call_for_channel(event['Channel'])) ||
          (event['Channel1'] && call_for_channel(event['Channel1'])) ||
          (event['Channel2'] && call_for_channel(event['Channel2']))
      end

      def handle_async_agi_start_event(event)
        env = RubyAMI::AsyncAGIEnvironmentParser.new(event['Env']).to_hash

        return if env[:agi_extension] == 'h' || env[:agi_type] == 'Kill'

        call = Call.new_link event['Channel'], current_actor, ami_client, connection, env
        register_call call
        call.async.send_offer
      end
    end
  end
end
