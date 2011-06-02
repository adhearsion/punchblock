module Punchblock
  module Protocol
    module Ozone
      class Transfer < Message
        ##
        # Creates a transfer message for Ozone
        #
        # @param [String] The destination for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com)
        #
        # @param [Hash] options for transferring a call
        # @option options [String, Optional] :terminator
        #
        # @return [Ozone::Message::Transfer] an Ozone "transfer" message
        #
        # @example
        #   Transfer.new('sip:myapp@mydomain.com', :terminator => '#').to_xml
        #
        #   returns:
        #     <transfer xmlns="urn:xmpp:ozone:transfer:1" to="sip:myapp@mydomain.com" terminator="#"/>
        def self.new(to, options = {})
          super('transfer').tap do |msg|
            options[:to] = to
            msg.set_options options
          end
        end

        def set_options options
          options.each do |option, value|
            @xml.set_attribute option.to_s.gsub('_', '-'), value.to_s
          end
        end
      end
    end
  end
end
