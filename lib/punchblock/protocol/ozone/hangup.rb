module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone hangup message
      #
      class Hangup < Message
        register :ozone_hangup, :hangup, 'urn:xmpp:ozone:1'

        include HasHeaders

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if hangup = node.document.find_first('//ns:hangup', :ns => self.registered_ns)
            hangup.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(:type => node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a hangup node is created
        # @private
        def self.new(options = {})
          new_node = super options[:type]
          new_node.hangup
          new_node.headers = options[:headers]
          new_node
        end

        # Overrides the parent to ensure the hangup node is destroyed
        # @private
        def inherit(node)
          remove_children :hangup
          super
        end

        # Get or create the hangup node on the stanza
        #
        # @return [Blather::XMPPNode]
        def hangup
          unless p = find_first('ns:hangup', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('hangup', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end
        alias :main_node :hangup

        def call_id
          to.node
        end

        def command_id
          to.resource
        end
      end # Hangup
    end # Ozone
  end # Protocol
end # Punchblock
