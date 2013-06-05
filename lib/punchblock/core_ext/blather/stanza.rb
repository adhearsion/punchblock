# encoding: utf-8

module Blather
  class Stanza
    ##
    # @return [Punchblock::RayoNode] a child of RayoNode
    #   representing the Rayo command/event contained within the stanza
    #
    def rayo_node
      first_child = at_xpath '*'
      Punchblock::RayoNode.from_xml first_child, nil, component_id if first_child
    rescue Punchblock::RayoNode::InvalidNodeError
      nil
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
  end
end
