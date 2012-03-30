# encoding: utf-8

module Punchblock
  class Event
    module ActiveSpeaker
      def call_id
        read_attr :'call-id'
      end

      def call_id=(other)
        write_attr :'call-id', other
      end

      def inspect_attributes # :nodoc:
        [:call_id] + super
      end
    end
  end
end
