# encoding: utf-8

require 'ruby_ami'

module Punchblock
  module Connection
    class Asterisk < GenericConnection
      attr_reader :ami_client, :translator
      attr_accessor :event_handler

      def initialize(options = {})
        @ami_client = RubyAMI::Stream.new options[:host], options[:port], options[:username], options[:password], ->(event) { translator.async.handle_ami_event event }, pb_logger
        @translator = Translator::Asterisk.new @ami_client, self, options[:media_engine]
        super()
      end

      def run
        ami_client.async.run
        Celluloid::Actor.join(ami_client)
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
    end
  end
end
