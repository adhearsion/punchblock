module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone hangup message
      #
      # @example
      #    Hangup.new.to_xml
      #
      #    returns:
      #        <hangup xmlns="urn:xmpp:ozone:1"/>
      class Hangup < Message
        def self.new
          super 'hangup'
        end
      end
    end
  end
end
