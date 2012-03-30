# encoding: utf-8

module Punchblock
  class Event
    class Joined < Event
      register :joined, :core

      ##
      # @return [String] the call ID that was joined
      def call_id
        read_attr :'call-id'
      end

      ##
      # @param [String] other the call ID that was joined
      def call_id=(other)
        write_attr :'call-id', other
      end

      ##
      # @return [String] the mixer name that was joined
      def mixer_name
        read_attr :'mixer-name'
      end

      ##
      # @param [String] other the mixer name that was joined
      def mixer_name=(other)
        write_attr :'mixer-name', other
      end

      def inspect_attributes # :nodoc:
        [:call_id, :mixer_name] + super
      end
    end # Joined
  end
end # Punchblock
