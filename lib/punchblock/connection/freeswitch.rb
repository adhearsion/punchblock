# encoding: utf-8

require 'ruby_fs'

module Punchblock
  module Connection
    class Freeswitch < GenericConnection
      attr_reader :translator, :stream
      attr_accessor :event_handler

      def initialize(options = {})
        @translator = Translator::Freeswitch.new self
        @stream = new_fs_stream(*options.values_at(:host, :port, :password))
        super()
      end

      def run
        pb_logger.debug "Starting the RubyFS stream"
        @stream.run
        raise DisconnectedError
      end

      def stop
        stream.shutdown
        translator.shutdown!
      end

      def write(command, options)
        translator.execute_command! command, options
      end

      def handle_event(event)
        event_handler.call event if event_handler.respond_to?(:call)
      end

      private

      def new_fs_stream(*args)
        RubyFS::Stream.new(*args, lambda { |e| translator.handle_es_event! e })
      end
    end
  end
end
