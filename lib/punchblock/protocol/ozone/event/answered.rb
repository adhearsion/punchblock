module Punchblock
  module Protocol
    class Ozone
      module Event
        class Answered < OzoneNode
          register :answered, :core
        end # End
      end # Event
    end # Ozone
  end # Protocol
end # Punchblock
