# encoding: utf-8

require 'ruby_ami'

module Punchblock
  module Connection
    class Asterisk < GenericConnection
      attr_reader :ami_client, :translator
      attr_accessor :event_handler

      def initialize(options = {})
        @stream_options = options
        @ami_client = RubyAMI::PooledStream.new(
          @stream_options.merge({
            event_callback:->(event) { translator.async.handle_ami_event event },
            logger: pb_logger
          })
        )
        @translator = Translator::Asterisk.new @ami_client, self
        super()
      end

      def run
        ami_client.run
        raise DisconnectedError
      end

      def stop
        translator.terminate
        ami_client.terminate
      end

      def write(command, options)
        translator.async.execute_command command, options
      end

      def send_message(*args)
        translator.send_message *args
      end

      def handle_event(event)
        event_handler.call event
      end

      def new_call_uri
        Punchblock.new_uuid
      end
    end
  end
end
