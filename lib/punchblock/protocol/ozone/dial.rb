module Punchblock
  module Protocol
    module Ozone
      class Dial < Command
        ##
        # Create a dial message
        #
        # @param [Hash] options for dialing a call
        # @option options [String] :to destination to dial
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

        def self.new(options = {})
          super().tap do |new_node|
            new_node.to = options[:to]
            new_node.from = options[:from]
            new_node.headers = options[:headers]
          end
        end

        def to
          read_attr :to
        end

        def to=(dial_to)
          write_attr :to, dial_to
        end

        def from
          read_attr :from
        end

        def from=(dial_from)
          write_attr :from, dial_from
        end

        def attributes
          [:to, :from] + super
        end
      end # Dial
    end # Ozone
  end # Protocol
end # Punchblock
