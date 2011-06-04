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
        register :ozone_reject, :reject, 'urn:xmpp:ozone:1'

        include HasHeaders

        VALID_REASONS = [:busy, :declined, :error].freeze

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if reject = node.document.find_first('//ns:reject', :ns => self.registered_ns)
            reject.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(nil, {:type => node[:type]}).inherit(node)
        end

        # Overrides the parent to ensure a reject node is created
        # @private
        def self.new(reason = :declined, options = {})
          new_node = super options[:type]
          new_node.reject
          new_node.reject_reason = reason
          new_node.headers = options[:headers]
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
        alias :main_node :reject

        def reject_reason
          reject.children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
        end

        def reject_reason=(reject_reason)
          if reject_reason && !VALID_REASONS.include?(reject_reason.to_sym)
            raise ArgumentError, "Invalid Reason (#{reject_reason}), use: #{VALID_REASONS*' '}"
          end
          reject.children.each &:remove
          reject << ::Blather::XMPPNode.new(reject_reason)
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
