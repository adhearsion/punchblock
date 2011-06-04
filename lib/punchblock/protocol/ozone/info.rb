module Punchblock
  module Protocol
    module Ozone
      class Info < Message
        register :ozone_info, :info, 'urn:xmpp:ozone:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if info = node.document.find_first('//ns:info', :ns => self.registered_ns)
            info.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(:type => node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a info node is created
        # @private
        def self.new(options = {})
          new_node = super options[:type]
          new_node.info
          new_node
        end

        # Overrides the parent to ensure the info node is destroyed
        # @private
        def inherit(node)
          remove_children :info
          super
        end

        # Get or create the info node on the stanza
        #
        # @return [Blather::XMPPNode]
        def info
          unless p = find_first('ns:info', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('info', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def event_name
          info.children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end

        def call_id
          from.node
        end

        def command_id
          from.resource
        end
      end # Info
    end # Ozone
  end # Protocol
end # Punchblock
