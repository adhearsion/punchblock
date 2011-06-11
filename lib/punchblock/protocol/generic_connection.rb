module Punchblock
  module Protocol
    ##
    # This exception may be raised if a protocol error is detected.
    ProtocolError = Class.new StandardError

    class GenericConnection
      def connected
        'CONNECTED'
      end

      def initialize(options = {})
        @event_queue = Queue.new
        @logger = options.delete(:transport_logger) if options[:transport_logger]
      end
    end
  end
end
