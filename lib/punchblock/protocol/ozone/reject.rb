module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone reject message
      #
      # @example
      #    Reject.new.to_xml
      #
      #    returns:
      #        <reject xmlns="urn:xmpp:ozone:1"/>
      class Reject < Message
        # def self.new(reason = :declined)
        #   raise ArgumentError unless [:busy, :declined, :error].include? reason
        #   super('reject').tap do |msg|
        #     Nokogiri::XML::Builder.with(msg.instance_variable_get(:@xml)) do |xml|
        #       xml.send reason.to_sym
        #     end
        #   end
        # end

        register :ozone_reject, :reject, 'urn:xmpp:ozone:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if reject = node.document.find_first('//ns:reject', :ns => self.registered_ns)
            reject.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a reject node is created
        # @private
        def self.new(type = nil)
          new_node = super type
          new_node.reject
          new_node
        end

        # Overrides the parent to ensure the reject node is destroyed
        # @private
        def inherit(node)
          remove_children :reject
          super
        end

        # Get or create the reject node on the stanza
        #
        # @return [Blather::XMPPNode]
        def reject
          unless p = find_first('ns:reject', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('reject', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def reject_reason
          reject.children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end

        def headers
          reject.find('ns:header', :ns => self.class.registered_ns).inject({}) do |headers, header|
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
      end # Reject
    end # Ozone
  end # Protocol
end # Punchblock
