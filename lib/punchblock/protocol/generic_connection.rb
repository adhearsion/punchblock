module Punchblock
  module Protocol
    ##
    # This exception may be raised if a protocol error is detected.
    ProtocolError = Class.new StandardError

    class GenericConnection
      attr_accessor :event_queue

      ##
      # @param [Hash] options
      # @option options [Logger] :transport_logger The logger to which transport events will be logged
      #
      def initialize(options = {})
        @event_queue = Queue.new
        @logger = options.delete(:transport_logger) if options[:transport_logger]
      end

      def connected
        'CONNECTED'
      end
    end
  end
end
