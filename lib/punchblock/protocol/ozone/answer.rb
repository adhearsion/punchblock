module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone answer message.  This is equivalent to a SIP "200 OK"
      #
      # @example
      #    Answer.new.to_xml
      #
      #    returns:
      #        <answer xmlns="urn:xmpp:ozone:1"/>
      class Answer < Message
        def self.new
          super 'answer'
        end
      end # Answer
    end # Ozone
  end # Protocol
end # Punchblock
