module Punchblock
  class Event
    class DTMF < Event
      register :dtmf, :core

      ##
      # Create a DTMF event
      #
      # @param [Hash] options
      # @option options [String, Optional] :signal the DTMF signal received
      #
      # @return [Event::DTMF] a formatted Rayo DTMF event
      #
      def self.new(options = {})
        super().tap do |new_node|
          case options
          when Nokogiri::XML::Node
            new_node.inherit options
          when Hash
            options.each_pair { |k,v| new_node.send :"#{k}=", v }
          end
        end
      end

      def signal
        read_attr :signal
      end

      def signal=(other)
        write_attr :signal, other
      end

      def inspect_attributes # :nodoc:
        [:signal] + super
      end
    end # End
  end
end # Punchblock
