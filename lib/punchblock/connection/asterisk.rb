# encoding: utf-8

require 'ruby_ami'

module Punchblock
  module Connection
    class Asterisk < GenericConnection
      attr_reader :ami_client, :translator

      def initialize(options = {})
        @ami_client = RubyAMI::Stream.new_link options[:host], options[:port], options[:username], options[:password], ->(event) { translator.async.handle_ami_event event }, pb_logger
        @translator = Translator::Asterisk.new_link @ami_client, current_actor, options[:media_engine]
        super()
      end

      def run
        ami_client.async.run
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
