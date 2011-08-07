module Punchblock
  class Rayo
    module Event
      class End < RayoNode
        register :end, :core

        def reason
          children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end

        def inspect_attributes # :nodoc:
          [:reason] + super
        end
      end # End
    end
  end # Rayo
end # Punchblock
