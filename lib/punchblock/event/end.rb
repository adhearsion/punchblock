# encoding: utf-8

module Punchblock
  class Event
    class End < Event
      register :end, :core

      include HasHeaders

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
