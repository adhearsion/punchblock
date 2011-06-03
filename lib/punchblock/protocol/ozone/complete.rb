module Punchblock
  module Protocol
    module Ozone
      class Complete < Message
        # attr_accessor :attributes, :xmlns
        #
        # def self.parse(xml, options)
        #   self.new('complete', options).tap do |info|
        #     info.attributes = {}
        #     xml.first.attributes.each { |k, v| info.attributes[k.to_sym] = v.value }
        #     info.xmlns = xml.first.namespace.href
        #   end
        #   # TODO: Validate response and return response type.
        #   # -----
        #   # <complete xmlns="urn:xmpp:ozone:say:1" reason="SUCCESS"/>
        # end

        register :ozone_complete, :complete, 'urn:xmpp:ozone:ext:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if complete = node.document.find_first('//ns:complete', :ns => self.registered_ns)
            complete.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a complete node is created
        # @private
        def self.new(type = nil)
          new_node = super type
          new_node.complete
          new_node
        end

        # Overrides the parent to ensure the complete node is destroyed
        # @private
        def inherit(node)
          remove_children :complete
          super
        end

        # Get or create the complete node on the stanza
        #
        # @return [Blather::XMPPNode]
        def complete
          unless p = find_first('ns:complete', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('complete', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def complete_type
          complete.children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end

        def call_id
          from.node
        end

        def command_id
          from.resource
        end
      end # Complete
    end # Ozone
  end # Protocol
end # Punchblock
