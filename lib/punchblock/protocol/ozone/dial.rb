module Punchblock
  module Protocol
    module Ozone
      class Dial < Message
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
        def self.new(options)
          super('dial').tap do |msg|
            msg.set_options options
          end
        end

        def set_options(options)
          options.each { |option, value| @xml.set_attribute option.to_s, value }
        end
      end
    end
  end
end
