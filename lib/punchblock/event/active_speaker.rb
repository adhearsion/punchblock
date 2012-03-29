# encoding: utf-8

module Punchblock
  class Event
    module ActiveSpeaker
      def other_call_id
        read_attr :'call-id'
      end

      def other_call_id=(other)
        write_attr :'call-id', other
      end

      def inspect_attributes # :nodoc:
        [:other_call_id] + super
      end
    end
  end
end
