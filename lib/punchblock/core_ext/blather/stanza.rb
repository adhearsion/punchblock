module Blather
  class Stanza
    def call_id
      from.node
    end

    def command_id
      from.resource
    end
  end
end
