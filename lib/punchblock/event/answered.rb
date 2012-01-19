module Punchblock
  class Event
    class Answered < Event
      register :answered, :core

      include HasHeaders
    end # End
  end # Event
end # Punchblock
