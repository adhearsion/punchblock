# encoding: utf-8

module Punchblock
  module Connection
    Disconnected = Class.new do
      def source
        nil
      end

      def client=(other)
        nil
      end

      def eql?(other)
        other.is_a? self.class
      end
      alias :== :eql?
    end
  end
end
