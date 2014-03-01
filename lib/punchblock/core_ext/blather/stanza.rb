# encoding: utf-8

module Blather
  class Stanza
    RAYO_NODE_PATH = "(#{Punchblock::RAYO_NAMESPACES.keys.map { |k| "#{k}:*" }.join("|")})".freeze
    ##
    # @return [Punchblock::RayoNode] a child of RayoNode
    #   representing the Rayo command/event contained within the stanza
    #
    def rayo_node
      @rayo_node ||= begin
        first_child = at_xpath RAYO_NODE_PATH, Punchblock::RAYO_NAMESPACES
        Punchblock::RayoNode.from_xml first_child, nil, component_id, "xmpp:#{from}", delay_timestamp if first_child
      end
    end

    ##
    # @return [String] the call ID this stanza applies to
    #
    def call_id
      from.node
    end

    ##
    # @return [String] the command ID this stanza applies to
    #
    def component_id
      from.resource
    end

  private

    def delay_timestamp
      if delay = self.at_xpath('ns:delay', ns: 'urn:xmpp:delay')
        DateTime.parse(delay[:stamp])
      end
    end
  end
end
