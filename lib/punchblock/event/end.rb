module Punchblock
  class Event
    class End < Event
      register :end, :core

      include HasHeaders

      ##
      # Create an End event
      #
      # @param [Hash] options
      # @option options [String, Optional] :reason the end reason
      #
      # @return [Event::End] a formatted Rayo end event
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

      def reason
        children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
      end

      def reason=(other)
        self << Nokogiri::XML::Element.new(other.to_s, self.document)
      end

      def inspect_attributes # :nodoc:
        [:reason] + super
      end
    end # End
  end
end # Punchblock
