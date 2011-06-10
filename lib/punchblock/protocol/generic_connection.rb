module Punchblock
  module Protocol
    ##
    # This exception may be raised if a protocol error is detected.
    class ProtocolError < StandardError; end

    class GenericConnection
      def connected
        'CONNECTED'
      end

      def initialize(options = {})
        @event_queue = Queue.new
        @logger = options.delete(:transport_logger) if options[:transport_logger]
      end

      # Blank class. Used primarily for testing.
      class Message # :nodoc:
      end
    end
  end
end
