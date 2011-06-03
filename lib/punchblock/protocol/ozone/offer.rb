module Punchblock
  module Protocol
    module Ozone
      class Offer < Message
        register :ozone_offer, :offer, 'urn:xmpp:ozone:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if offer = node.document.find_first('//ns:offer', :ns => self.registered_ns)
            offer.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a offer node is created
        # @private
        def self.new(type = nil)
          new_node = super type
          new_node.offer
          new_node
        end

        # Overrides the parent to ensure the offer node is destroyed
        # @private
        def inherit(node)
          remove_children :offer
          super
        end

        # Get or create the offer node on the stanza
        #
        # @return [Blather::XMPPNode]
        def offer
          unless p = find_first('ns:offer', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('offer', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def offer_to
          offer[:to]
        end

        def offer_from
          offer[:from]
        end

        def headers
          offer.find('ns:header', :ns => self.class.registered_ns).inject({}) do |headers, header|
            headers[header[:name].gsub('-','_').downcase.to_sym] = header[:value]
            headers
          end
        end

        def call_id
          from.node
        end

        def command_id
          from.resource
        end
      end # Offer
    end # Ozone
  end # Protocol
end # Punchblock
