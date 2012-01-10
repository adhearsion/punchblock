require 'celluloid'
require 'ruby_ami'

module Punchblock
  module Translator
    class Asterisk
      include Celluloid

      extend ActiveSupport::Autoload

      autoload :Call
      autoload :Component

      attr_reader :ami_client, :connection, :media_engine, :calls

      def initialize(ami_client, connection, media_engine = nil)
        pb_logger.debug "Starting up..."
        @ami_client, @connection, @media_engine = ami_client, connection, media_engine
        @calls, @components, @channel_to_call_id = {}, {}, {}
        @fully_booted_count = 0
      end

      def register_call(call)
        @channel_to_call_id[call.channel] = call.id
        @calls[call.id] ||= call
      end

      def call_with_id(call_id)
        @calls[call_id]
      end

      def call_for_channel(channel)
        call = call_with_id @channel_to_call_id[channel]
        pb_logger.trace "Looking up call for channel #{channel} from #{@channel_to_call_id}. Found: #{call || 'none'}"
        call
      end

      def register_component(component)
        @components[component.id] ||= component
      end

      def component_with_id(component_id)
        @components[component_id]
      end

      def handle_ami_event(event)
        return unless event.is_a? RubyAMI::Event
        pb_logger.trace "Handling AMI event #{event.inspect}"
        if event.name.downcase == "fullybooted"
          pb_logger.trace "Counting FullyBooted event"
          @fully_booted_count += 1
          if @fully_booted_count >= 2
            handle_pb_event Connection::Connected.new
            @fully_booted_count = 0
          end
          return
        end
        if event.name.downcase == "asyncagi" && event['SubEvent'] == "Start"
          handle_async_agi_start_event event
        end
        if call = call_for_channel(event['Channel'])
          pb_logger.trace "Found call by channel matching this event. Sending to call #{call.id}"
          call.process_ami_event! event
        end
        handle_pb_event Event::Asterisk::AMI::Event.new(:name => event.name, :attributes => event.headers)
      end

      def handle_pb_event(event)
        connection.handle_event event
      end

      def execute_command(command, options = {})
        pb_logger.debug "Executing command #{command.inspect}"
        command.request!

        command.call_id ||= options[:call_id]
        command.component_id ||= options[:component_id]

        if command.call_id
          execute_call_command command
        elsif command.component_id
          execute_component_command command
        else
          execute_global_command command
        end
      end

      def execute_call_command(command)
        call_with_id(command.call_id).execute_command! command
      end

      def execute_component_command(command)
        component_with_id(command.component_id).execute_command! command
      end

      def execute_global_command(command)
        component = Component::Asterisk::AMIAction.new command, current_actor
        register_component component
        component.execute!
      end

      def send_ami_action(name, headers = {}, &block)
        ami_client.send_action name, headers, &block
      end

      private

      def handle_async_agi_start_event(event)
        call = Call.new event['Channel'], current_actor, event['Env']
        register_call call
        call.send_offer!
      end
    end
  end
end
