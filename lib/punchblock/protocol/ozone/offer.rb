module Punchblock
  module Protocol
    module Ozone
      class Offer < Message
        ##
        # Creates an Offer message.
        # This message may not be sent by a client; this object is used
        # to represent an offer received from the Ozone server.
        def self.parse(xml, options)
          self.new 'offer', options
        end
      end
    end
  end
end
