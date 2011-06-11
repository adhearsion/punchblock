module Blather
  class Stanza
    def ozone_node
      Protocol::Ozone::OzoneNode.import children.first, call_id, command_id
    end

    def call_id
      from.node
    end

    def command_id
      from.resource
    end
  end
end
