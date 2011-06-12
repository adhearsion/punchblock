module Blather
  class Stanza
    ##
    # @return [Punchblock::Protocol::Ozone::OzoneNode] a child of OzoneNode
    #   representing the Ozone command/event contained within the stanza
    #
    def ozone_node
      first_child = children.first
      Punchblock::Protocol::Ozone::OzoneNode.import first_child, call_id, command_id if first_child
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
