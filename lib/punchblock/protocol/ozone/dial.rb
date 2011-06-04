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
        register :ozone_dial, :dial, 'urn:xmpp:ozone:1'

        include HasHeaders

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if dial = node.document.find_first('//ns:dial', :ns => self.registered_ns)
            dial.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new({:type => node[:type]}).inherit(node)
        end

        # Overrides the parent to ensure a dial node is created
        # @private
        def self.new(dial_to = nil, dial_from = nil, options = {})
          new_node = super options[:type]
          new_node.dial
          new_node.dial_to = dial_to
          new_node.dial_from = dial_from
          new_node.headers = options[:headers]
          new_node
        end

        # Overrides the parent to ensure the dial node is destroyed
        # @private
        def inherit(node)
          remove_children :dial
          super
        end

        # Get or create the dial node on the stanza
        #
        # @return [Blather::XMPPNode]
        def dial
          unless p = find_first('ns:dial', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('dial', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end
        alias :main_node :dial

        def dial_to
          dial[:to]
        end

        def dial_to=(dial_to)
          dial[:to] = dial_to
        end

        def dial_from
          dial[:from]
        end

        def dial_from=(dial_from)
          dial[:from] = dial_from
        end
      end # Dial
    end # Ozone
  end # Protocol
end # Punchblock
