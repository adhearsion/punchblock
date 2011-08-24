module Punchblock
  class Event
    class Info < Event
      register :info, :core

      def event_name
        children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
      end

      def inspect_attributes # :nodoc:
        [:event_name] + super
      end
    end # Info
  end
end # Punchblock
