require 'celluloid'

module Celluloid
  class Actor
    attr_reader :subject
  end

  class ActorProxy
    def actor_subject
      @actor.subject
    end
  end
end

module Punchblock
  module Translator
    class Asterisk
      include Celluloid

      extend ActiveSupport::Autoload

      autoload :Call
      autoload :Component

      attr_reader :ami_client, :connection

      def initialize(ami_client, connection)
        @ami_client, @connection = ami_client, connection
        @calls = {}
      end

      def register_call(call)
        @calls[call.id] ||= call
      end

      def call_with_id(call_id)
        @calls[call_id]
      end

      def handle_ami_event(event)
      end

      def execute_command(command, options = {})
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
        call_with_id(command.call_id).execute_command command
      end

      def execute_component_command(command)
        call_with_id(command.call_id).execute_component_command command
      end

      def execute_global_command(command)

      end
    end
  end
end
