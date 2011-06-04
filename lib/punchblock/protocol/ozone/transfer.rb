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
        register :ozone_transfer, :transfer, 'urn:xmpp:ozone:transfer:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if transfer = node.document.find_first('//ns:transfer', :ns => self.registered_ns)
            transfer.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a transfer node is created
        # @private
        def self.new(transfer_to = '', options = {})
          new_node = super()
          new_node.transfer
          new_node.transfer_to = transfer_to
          new_node.transfer_from = options[:from]
          new_node.terminator = options[:terminator]
          new_node.timeout = options[:timeout]
          new_node.answer_on_media = options[:answer_on_media]
          new_node
        end

        # Overrides the parent to ensure the transfer node is destroyed
        # @private
        def inherit(node)
          remove_children :transfer
          super
        end

        # Get or create the transfer node on the stanza
        #
        # @return [Blather::XMPPNode]
        def transfer
          unless p = find_first('ns:transfer', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('transfer', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def transfer_to
          transfer.find('ns:to', :ns => self.class.registered_ns).map &:text
        end

        def transfer_to=(transfer_to)
          transfer.find('//ns:to', :ns => self.class.registered_ns).each &:remove
          if transfer_to
            [transfer_to].flatten.each do |i|
              to = ::Blather::XMPPNode.new :to
              to << i
              self.transfer << to
            end
          end
        end

        def transfer_from
          transfer[:from]
        end

        def transfer_from=(transfer_from)
          transfer[:from] = transfer_from
        end

        def terminator
          transfer[:terminator]
        end

        def terminator=(terminator)
          transfer[:terminator] = terminator
        end

        def timeout
          transfer[:timeout].to_i
        end

        def timeout=(timeout)
          transfer[:timeout] = timeout
        end

        def answer_on_media
          transfer['answer-on-media'] == 'true'
        end

        def answer_on_media=(aom)
          transfer['answer-on-media'] = aom.to_s
        end

        def call_id
          to.node
        end

        def command_id
          to.resource
        end
      end # Transfer
    end # Ozone
  end # Protocol
end # Punchblock
