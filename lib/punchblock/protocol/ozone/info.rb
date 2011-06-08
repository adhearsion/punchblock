module Punchblock
  module Protocol
    module Ozone
      class Info < Event
        register :info, :core

        def event_name
          children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end
      end # Info
    end # Ozone
  end # Protocol
end # Punchblock
