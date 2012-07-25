# encoding: utf-8

require 'ruby_ami'

module Punchblock
  module Connection
    class Asterisk < GenericConnection
      attr_reader :ami_client, :translator
      attr_accessor :event_handler

      def initialize(options = {})
        @ami_client = RubyAMI::Client.new options.merge(:event_handler => lambda { |event| translator.handle_ami_event! event }, :logger => pb_logger)
        @translator = Translator::Asterisk.new @ami_client, self, options[:media_engine]
        super()
      end

      def run
        ami_client.start
        raise DisconnectedError
      end

      def stop
        translator.shutdown!
        ami_client.stop
      end

      def write(command, options)
        translator.execute_command! command, options
      end

      def handle_event(event)
        event_handler.call event
      end
    end
  end
end
