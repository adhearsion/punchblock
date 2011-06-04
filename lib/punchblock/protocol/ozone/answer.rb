module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone answer message.  This is equivalent to a SIP "200 OK"
      #
      # @example
      #    Answer.new.to_xml
      #
      #    returns:
      #        <answer xmlns="urn:xmpp:ozone:1"/>
      class Answer < Message
        register :ozone_answer, :answer, 'urn:xmpp:ozone:1'

        include HasHeaders

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if answer = node.document.find_first('//ns:answer', :ns => self.registered_ns)
            answer.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new({:type => node[:type]}).inherit(node)
        end

        # Overrides the parent to ensure a answer node is created
        # @private
        def self.new(options = {})
          new_node = super options[:type]
          new_node.answer
          new_node.headers = options[:headers]
          new_node
        end

        # Overrides the parent to ensure the answer node is destroyed
        # @private
        def inherit(node)
          remove_children :answer
          super
        end

        # Get or create the answer node on the stanza
        #
        # @return [Blather::XMPPNode]
        def answer
          unless p = find_first('ns:answer', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('answer', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end
        alias :main_node :answer

        def call_id
          to.node
        end

        def command_id
          to.resource
        end
      end # Answer
    end # Ozone
  end # Protocol
end # Punchblock
