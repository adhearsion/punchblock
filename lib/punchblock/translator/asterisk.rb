require 'celluloid'
require 'punchblock/core_ext/celluloid'
require 'ruby_ami'

module Punchblock
  module Translator
    class Asterisk
      include Celluloid

      extend ActiveSupport::Autoload

      autoload :Call
      autoload :Component

      attr_reader :ami_client, :connection, :calls

      def initialize(ami_client, connection)
        @ami_client, @connection = ami_client, connection
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
        call_with_id @channel_to_call_id[channel]
      end

      def register_component(component)
        @components[component.id] ||= component
      end

      def component_with_id(component_id)
        @components[component_id]
      end

      def handle_ami_event(event)
        return unless event.is_a? RubyAMI::Event
        if event.name.downcase == "fullybooted"
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
          call.process_ami_event! event
        end
        handle_pb_event Event::Asterisk::AMI::Event.new(:name => event.name, :attributes => event.headers)
      end

      def handle_pb_event(event)
        connection.handle_event event
      end

      def execute_command(command, options = {})
        command.request!
        if command.call_id || options[:call_id]
          command.call_id ||= options[:call_id]
          if command.component_id || options[:component_id]
            command.component_id ||= options[:component_id]
            execute_component_command command
          else
            execute_call_command command
          end
        else
          execute_global_command command
        end
      end

      def execute_call_command(command)
        call_with_id(command.call_id).execute_command! command
      end

      def execute_component_command(command)
        call_with_id(command.call_id).execute_component_command! command
      end

      def execute_global_command(command)
        component = Component::Asterisk::AMIAction.new command, current_actor
        # register_component component
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
