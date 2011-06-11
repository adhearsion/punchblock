module Blather
  class Stanza
    def ozone_node
      first_child = children.first
      Punchblock::Protocol::Ozone::OzoneNode.import first_child, call_id, command_id if first_child
    end

    def call_id
      from.node
    end

    def command_id
      from.resource
    end
  end
end
