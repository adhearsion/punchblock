module Punchblock
  module Transport
    class GenericTransport
      def initialize(protocol, options = {})
        @event_queue = Queue.new
        @logger = options.delete(:transport_logger)
        @protocol = protocol
      end
    end
  end
end
