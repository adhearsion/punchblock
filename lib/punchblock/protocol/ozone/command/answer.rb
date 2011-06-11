module Punchblock
  module Protocol
    class Ozone
      module Command
        ##
        # An Ozone answer message.  This is equivalent to a SIP "200 OK"
        #
        # @example
        #    Answer.new.to_xml
        #
        #    returns:
        #        <answer xmlns="urn:xmpp:ozone:1"/>
        class Answer < OzoneNode
          register :answer, :core

          include HasHeaders

          # Overrides the parent to ensure a answer node is created
          # @private
          def self.new(options = {})
            super().tap do |new_node|
              new_node.headers = options[:headers]
            end
          end
        end # Answer
      end
    end # Ozone
  end # Protocol
end # Punchblock
