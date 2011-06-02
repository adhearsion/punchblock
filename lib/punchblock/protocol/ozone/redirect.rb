module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone redirect message
      #
      # @example
      #    Redirect.new('tel:+14045551234').to_xml
      #
      #    returns:
      #        <redirect to="tel:+14045551234" xmlns="urn:xmpp:ozone:1"/>
      class Redirect < Message
        def self.new(destination)
          super('redirect').tap do |msg|
            msg.set_destination destination
          end
        end

        def set_destination(dest)
          @xml.set_attribute 'to', dest
        end
      end # Redirect
    end # Ozone
  end # Protocol
end # Punchblock
