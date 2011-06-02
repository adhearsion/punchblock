module Punchblock
  module Protocol
    module Ozone
      class End < Message
        attr_accessor :type

        ##
        # Creates an End message.  This signifies the end of a call.
        # This message may not be sent by a client; this object is used
        # to represent an offer received from the Ozone server.
        def self.parse(xml, options)
          self.new('end', options).tap do |info|
            event = xml.first.children.first
            info.type = event.name.to_sym
          end
        end
      end # End
    end # Ozone
  end # Protocol
end # Punchblock
