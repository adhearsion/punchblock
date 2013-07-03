# encoding: utf-8

require 'celluloid'

module Punchblock
  module Connection
    class GenericConnection
      include Celluloid

      attr_accessor :event_handler

      def initialize
        @event_handler = lambda { |event| raise 'No event handler set' }
      end

      def ready
      end

      def not_ready
      end

      def connected?
      end
    end
  end
end
