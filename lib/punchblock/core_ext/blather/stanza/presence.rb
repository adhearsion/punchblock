module Blather
  class Stanza
    class Presence
      def event
        Protocol::Ozone::OzoneNode.import children.first, call_id, command_id
      end
    end
  end
end
