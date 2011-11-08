module Punchblock
  class Event
    class Offer < Event
      register :offer, :core

      include HasHeaders

      ##
      # Create an Offer event
      #
      # @param [Hash] options
      # @option options [String, Optional] :to the call targed
      # @option options [String, Optional] :from the caller ID
      # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
      #   the call. Can be either a hash of key-value pairs, or an array of
      #   Header objects.
      #
      # @return [Event::Offer] a formatted Rayo offer event
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

      def to
        read_attr :to
      end

      def to=(offer_to)
        write_attr :to, offer_to
      end

      def from
        read_attr :from
      end

      def from=(offer_from)
        write_attr :from, offer_from
      end

      def inspect_attributes # :nodoc:
        [:to, :from] + super
      end
    end # Offer
  end
end # Punchblock
