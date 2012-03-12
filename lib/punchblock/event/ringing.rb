# encoding: utf-8

module Punchblock
  class Event
    class Ringing < Event
      register :ringing, :core

      include HasHeaders
    end # End
  end # Event
end # Punchblock
