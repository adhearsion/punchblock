module Punchblock
  module Protocol
    class Ozone
      module Event
        class Info < OzoneNode
          register :info, :core

          def event_name
            children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
          end

          def inspect_attributes # :nodoc:
            [:event_name] + super
          end
        end # Info
      end
    end # Ozone
  end # Protocol
end # Punchblock
