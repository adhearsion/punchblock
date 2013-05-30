# encoding: utf-8

require 'ruby_ami'

module Punchblock
  module Connection
    class Asterisk < GenericConnection
      attr_reader :ami_client, :translator
      attr_accessor :event_handler

      def initialize(options = {})
        @stream_options = options.values_at(:host, :port, :username, :password)
        @translator_options = options.values_at(:media_engine)
        new_ami_components
        super()
      end

      def run
        start_ami_client
        raise DisconnectedError
      end

      def stop
        translator.async.shutdown
        ami_client.terminate
      end

      def write(command, options)
        translator.async.execute_command command, options
      end

      def handle_event(event)
        event_handler.call event
      end

      def new_ami_components
        @ami_client = RubyAMI::Stream.new(*@stream_options, ->(event) { translator.async.handle_ami_event event }, pb_logger)
        @translator = Translator::Asterisk.new @ami_client, self, *@translator_options
      end

      def start_ami_client
        new_ami_components unless ami_client.alive?
        ami_client.async.run
        Celluloid::Actor.join(ami_client)
      end
    end
  end
end
