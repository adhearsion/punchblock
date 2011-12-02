module Punchblock
  class Event
    class Unjoined < Event
      register :unjoined, :core

      ##
      # Create an unjoined event
      #
      # @param [Hash] options
      # @option options [String, Optional] :other_call_id the call ID that was unjoined
      # @option options [String, Optional] :mixer_name the mixer name that was unjoined
      #
      # @return [Event::Unjoined] a formatted Rayo unjoined event
      #
      def self.new(options = {})
        super().tap do |new_node|
          options.each_pair { |k,v| new_node.send :"#{k}=", v }
        end
      end

      ##
      # @return [String] the call ID that was unjoined
      def other_call_id
        read_attr :'call-id'
      end

      ##
      # @param [String] other the call ID that was unjoined
      def other_call_id=(other)
        write_attr :'call-id', other
      end

      ##
      # @return [String] the mixer name that was unjoined
      def mixer_name
        read_attr :'mixer-name'
      end

      ##
      # @param [String] other the mixer name that was unjoined
      def mixer_name=(other)
        write_attr :'mixer-name', other
      end

      def inspect_attributes # :nodoc:
        [:other_call_id, :mixer_name] + super
      end
    end # Unjoined
  end
end # Punchblock
