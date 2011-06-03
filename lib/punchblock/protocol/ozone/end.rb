module Punchblock
  module Protocol
    module Ozone
      class End < Message
        register :ozone_end, :end, 'urn:xmpp:ozone:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if end_message = node.document.find_first('//ns:end', :ns => self.registered_ns)
            end_message.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a end_message node is created
        # @private
        def self.new(type = nil)
          new_node = super type
          new_node.end_message
          new_node
        end

        # Overrides the parent to ensure the end_message node is destroyed
        # @private
        def inherit(node)
          remove_children :end
          super
        end

        # Get or create the end_message node on the stanza
        #
        # @return [Blather::XMPPNode]
        def end_message
          unless p = find_first('ns:end', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('end', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def reason
          end_message.children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end

        def call_id
          from.node
        end

        def command_id
          from.resource
        end
      end # End
    end # Ozone
  end # Protocol
end # Punchblock
