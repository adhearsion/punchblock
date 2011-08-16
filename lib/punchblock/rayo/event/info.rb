module Punchblock
  class Rayo
    module Event
      class Info < RayoNode
        register :info, :core

        def event_name
          children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end

        def inspect_attributes # :nodoc:
          [:event_name] + super
        end
      end # Info
    end
  end # Rayo
end # Punchblock
