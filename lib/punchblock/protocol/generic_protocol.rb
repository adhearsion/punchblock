module Punchblock
  module Protocol
    ##
    # This exception may be raised if a protocol error is detected.
    class ProtocolError < StandardError; end

    class GenericProtocol
      def self.connected
        'CONNECTED'
      end

      # Blank class. Used primarily for testing.
      class Message # :nodoc:
      end
    end
  end
end
