module Punchblock
  class Event
    class Joined < Event
      register :joined, :core

      ##
      # Create a joined event
      #
      # @param [Hash] options
      # @option options [String, Optional] :other_call_id the call ID that was joined
      # @option options [String, Optional] :mixer_name the mixer name that was joined
      #
      # @return [Event::Joined] a formatted Rayo joined event
      #
      def self.new(options = {})
        super().tap do |new_node|
          options.each_pair { |k,v| new_node.send :"#{k}=", v }
        end
      end

      ##
      # @return [String] the call ID that was joined
      def other_call_id
        read_attr :'call-id'
      end

      ##
      # @param [String] other the call ID that was joined
      def other_call_id=(other)
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
        [:other_call_id, :mixer_name] + super
      end
    end # Joined
  end
end # Punchblock
