module Punchblock
  module Protocol
    module Ozone
      class Info < Message
        attr_accessor :type, :attributes

        def self.parse(xml, options)
          self.new('info', options).tap do |info|
            event = xml.first.children.first
            info.type = event.name.to_sym
            info.attributes = event.attributes.inject({}) do |h, (k, v)|
              h[k.downcase.to_sym] = v.value
              h
            end
          end
        end
      end # Info
    end # Ozone
  end # Protocol
end # Punchblock
