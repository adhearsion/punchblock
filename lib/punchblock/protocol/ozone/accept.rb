module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone accept message.  This is equivalent to a SIP "180 Trying"
      #
      # @example
      #    Accept.new.to_xml
      #
      #    returns:
      #        <accept xmlns="urn:xmpp:ozone:1"/>
      class Accept < Command
        register :accept, :core

        include HasHeaders

        def self.new(options = {})
          super().tap do |new_node|
            new_node.headers = options[:headers]
          end
        end
      end # Accept
    end # Ozone
  end # Protocol
end # Punchblock
