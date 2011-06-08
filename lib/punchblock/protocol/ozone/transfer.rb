module Punchblock
  module Protocol
    module Ozone
      class Transfer < Command
        register :transfer, :transfer

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
        def self.new(transfer_to = '', options = {})
          new_node = super()
          new_node.to = transfer_to
          new_node.from = options[:from]
          new_node.terminator = options[:terminator]
          new_node.timeout = options[:timeout]
          new_node.answer_on_media = options[:answer_on_media]
          new_node
        end

        def to
          find('ns:to', :ns => self.class.registered_ns).map &:text
        end

        def to=(transfer_to)
          find('//ns:to', :ns => self.class.registered_ns).each &:remove
          if transfer_to
            [transfer_to].flatten.each do |i|
              to = OzoneNode.new :to
              to << i
              self << to
            end
          end
        end

        def from
          self[:from]
        end

        def from=(transfer_from)
          self[:from] = transfer_from
        end

        def terminator
          self[:terminator]
        end

        def terminator=(terminator)
          self[:terminator] = terminator
        end

        def timeout
          self[:timeout].to_i
        end

        def timeout=(timeout)
          self[:timeout] = timeout
        end

        def answer_on_media
          self['answer-on-media'] == 'true'
        end

        def answer_on_media=(aom)
          self['answer-on-media'] = aom.to_s
        end
      end # Transfer
    end # Ozone
  end # Protocol
end # Punchblock
