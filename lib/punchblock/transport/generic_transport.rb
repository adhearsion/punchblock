module Punchblock
  module Transport
    class GenericTransport
      def initialize(protocol, options = {})
        @event_queue = Queue.new
        @logger = options.delete(:transport_logger) if options[:transport_logger]
        @protocol = if protocol.is_a? Class
          protocol
        else
          Punchblock::Protocol.const_get(protocol.to_s.capitalize)
        end
      end
    end
  end
end
