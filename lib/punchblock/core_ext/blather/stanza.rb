module Blather
  class Stanza
    ##
    # @return [Punchblock::Rayo::RayoNode] a child of RayoNode
    #   representing the Rayo command/event contained within the stanza
    #
    def rayo_node
      first_child = children.first
      Punchblock::Rayo::RayoNode.import first_child, call_id, command_id if first_child
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
    def command_id
      from.resource
    end
  end
end
