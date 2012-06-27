# encoding: utf-8

require 'librevox'

module Punchblock
  module Connection
    class Freeswitch < GenericConnection
      attr_reader :translator
      attr_accessor :event_handler

      def initialize(options = {})
        @translator = Translator::Freeswitch.new self
        super()
      end

      def run
        pb_logger.debug "Starting the librevox listener"
        EM.run do
          Librevox.run InboundListener, :event_handler => lambda { |e| translator.handle_es_event! e }
        end
        raise DisconnectedError
      end

      def stop
        translator.shutdown!
      end

      def write(command, options)
        translator.execute_command! command, options
      end

      def handle_event(event)
        event_handler.call event
      end

      class InboundListener < Librevox::Listener::Inbound
        def initialize(args)
          super
          @event_handler = args[:event_handler]
        end

        def on_event(e)
          @event_handler[e]
        end
      end
    end
  end
end
