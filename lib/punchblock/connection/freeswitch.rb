# encoding: utf-8

require 'ruby_fs'

module Punchblock
  module Connection
    class Freeswitch < GenericConnection
      attr_reader :translator, :stream
      attr_accessor :event_handler

      def initialize(options = {})
        @translator = Translator::Freeswitch.new self
        @stream_options = options.values_at(:host, :port, :password)
        @stream = new_fs_stream
        super()
      end

      def run
        pb_logger.debug "Starting the RubyFS stream"
        start_stream
        handle_event Connection::Disconnected.new
        raise DisconnectedError
      end

      def stop
        stream.shutdown
        translator.terminate
      end

      def write(command, options)
        translator.async.execute_command command, options
      end

      def handle_event(event)
        event_handler.call event if event_handler.respond_to?(:call)
      end

      private

      def new_fs_stream
        RubyFS::Stream.new(*@stream_options, lambda { |e| translator.async.handle_es_event e }, event_mask)
      end

      def event_mask
        %w{CHANNEL_PARK CHANNEL_ANSWER CHANNEL_STATE CHANNEL_HANGUP CHANNEL_BRIDGE CHANNEL_UNBRIDGE CHANNEL_EXECUTE_COMPLETE DTMF RECORD_STOP}
      end

      def start_stream
        @stream = new_fs_stream unless @stream.alive?
        @stream.run
      end
    end
  end
end
