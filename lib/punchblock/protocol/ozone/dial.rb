module Punchblock
  module Protocol
    module Ozone
      class Dial < Command
        ##
        # Create a dial message
        #
        # @param [Hash] options for dialing a call
        # @option options [Integer, Optional] :to destination to dial
        # @option options [String, Optional] :from what to set the Caller ID to
        #
        # @return [Ozone::Message] a formatted Ozone dial message
        #
        # @example
        #    dial :to => 'tel:+14155551212', :from => 'tel:+13035551212'
        #
        #    returns:
        #      <iq type='set' to='call.ozone.net' from='16577@app.ozone.net/1'>
        #        <dial to='tel:+13055195825' from='tel:+14152226789' xmlns='urn:xmpp:ozone:1' />
        #      </iq>
        register :dial, :core

        include HasHeaders

        def self.new(to = nil, from = nil, options = {})
          new_node = super()
          new_node.to = to
          new_node.from = from
          new_node.headers = options[:headers]
          new_node
        end

        def to
          self[:to]
        end

        def to=(dial_to)
          self[:to] = dial_to
        end

        def from
          self[:from]
        end

        def from=(dial_from)
          self[:from] = dial_from
        end
      end # Dial
    end # Ozone
  end # Protocol
end # Punchblock
