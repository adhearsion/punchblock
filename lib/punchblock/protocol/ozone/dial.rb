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

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if dial = node.document.find_first('//ns:dial', :ns => self.registered_ns)
            dial.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a dial node is created
        # @private
        def self.new(type = nil)
          new_node = super type
          new_node.dial
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

        def dial_to
          dial[:to]
        end

        def dial_from
          dial[:from]
        end

        def headers
          dial.find('ns:header', :ns => self.class.registered_ns).inject({}) do |headers, header|
            headers[header[:name].gsub('-','_').downcase.to_sym] = header[:value]
            headers
          end
        end
      end # Dial
    end # Ozone
  end # Protocol
end # Punchblock
