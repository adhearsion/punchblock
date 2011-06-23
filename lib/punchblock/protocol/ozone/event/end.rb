module Punchblock
  module Protocol
    class Ozone
      module Event
        class End < OzoneNode
          register :end, :core

          def reason
            children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
          end

          def inspect_attributes # :nodoc:
            [:reason] + super
          end
        end # End
      end
    end # Ozone
  end # Protocol
end # Punchblock
