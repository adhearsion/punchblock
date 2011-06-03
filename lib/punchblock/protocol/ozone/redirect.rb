module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone redirect message
      #
      # @example
      #    Redirect.new('tel:+14045551234').to_xml
      #
      #    returns:
      #        <redirect to="tel:+14045551234" xmlns="urn:xmpp:ozone:1"/>
      class Redirect < Message
        register :ozone_redirect, :redirect, 'urn:xmpp:ozone:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if redirect = node.document.find_first('//ns:redirect', :ns => self.registered_ns)
            redirect.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a redirect node is created
        # @private
        def self.new(type = nil)
          new_node = super type
          new_node.redirect
          new_node
        end

        # Overrides the parent to ensure the redirect node is destroyed
        # @private
        def inherit(node)
          remove_children :redirect
          super
        end

        # Get or create the redirect node on the stanza
        #
        # @return [Blather::XMPPNode]
        def redirect
          unless p = find_first('ns:redirect', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('redirect', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def redirect_to
          redirect[:to]
        end

        def headers
          redirect.find('ns:header', :ns => self.class.registered_ns).inject({}) do |headers, header|
            headers[header[:name].gsub('-','_').downcase.to_sym] = header[:value]
            headers
          end
        end

        def call_id
          to.node
        end

        def command_id
          to.resource
        end
      end # Redirect
    end # Ozone
  end # Protocol
end # Punchblock
