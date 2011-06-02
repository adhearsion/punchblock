module Punchblock
  module Protocol
    module Ozone
      class Complete < Message
        attr_accessor :attributes, :xmlns

        def self.parse(xml, options)
          self.new('complete', options).tap do |info|
            info.attributes = {}
            xml.first.attributes.each { |k, v| info.attributes[k.to_sym] = v.value }
            info.xmlns = xml.first.namespace.href
          end
          # TODO: Validate response and return response type.
          # -----
          # <complete xmlns="urn:xmpp:ozone:say:1" reason="SUCCESS"/>
        end
      end # Complete
    end # Ozone
  end # Protocol
end # Punchblock
