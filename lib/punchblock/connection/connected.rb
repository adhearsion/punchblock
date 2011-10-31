module Punchblock
  module Connection
    Connected = Class.new do
      def source
        nil
      end

      def client=(other)
        nil
      end
    end
  end
end
