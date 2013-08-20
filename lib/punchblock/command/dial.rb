# encoding: utf-8

module Punchblock
  module Command
    class Dial < CommandNode
      register :dial, :core

      include HasHeaders

      # @return [String] destination to dial
      attribute :to

      # @return [String] the caller ID
      attribute :from

      # @return [Integer] timeout in milliseconds
      attribute :timeout, Integer

      # @return [Join] the nested join
      attribute :join, Join

      def inherit(xml_node)
        if join_element = xml_node.at_xpath('ns:join', ns: Join.registered_ns)
          self.join = Join.from_xml(join_element)
        end
        super
      end

      def rayo_attributes
        {to: to, from: from, timeout: timeout}
      end

      def rayo_children(root)
        join.to_rayo(root.parent) if join
        super
      end

      def response=(other)
        if other.is_a?(Ref)
          @target_call_id = other.uri.node
          @domain = other.uri.domain
        end
        super
      end
    end
  end
end
