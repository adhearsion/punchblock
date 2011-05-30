module Punchblock
  module Protocol
    ##
    # This exception may be raised if a protocol error is detected.
    class ProtocolError < StandardError; end

    class GenericProtocol
      def self.connected
        'CONNECTED'
      end
    end
  end
end
