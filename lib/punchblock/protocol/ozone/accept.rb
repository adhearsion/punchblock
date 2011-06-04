module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone accept message.  This is equivalent to a SIP "180 Trying"
      #
      # @example
      #    Accept.new.to_xml
      #
      #    returns:
      #        <accept xmlns="urn:xmpp:ozone:1"/>
      class Accept < Message
        register :ozone_accept, :accept, 'urn:xmpp:ozone:1'

        include HasHeaders

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if accept = node.document.find_first('//ns:accept', :ns => self.registered_ns)
            accept.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new({:type => node[:type]}).inherit(node)
        end

        # Overrides the parent to ensure a accept node is created
        # @private
        def self.new(options = {})
          new_node = super options[:type]
          new_node.accept
          new_node.headers = options[:headers]
          new_node
        end

        # Overrides the parent to ensure the accept node is destroyed
        # @private
        def inherit(node)
          remove_children :accept
          super
        end

        # Get or create the accept node on the stanza
        #
        # @return [Blather::XMPPNode]
        def accept
          unless p = find_first('ns:accept', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('accept', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end
        alias :main_node :accept

        def call_id
          to.node
        end

        def command_id
          to.resource
        end
      end # Accept
    end # Ozone
  end # Protocol
end # Punchblock
