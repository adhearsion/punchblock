module Punchblock
  module Protocol
    module Ozone
      class End < Event
        register :end, :core

        def reason
          children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end
      end # End
    end # Ozone
  end # Protocol
end # Punchblock
