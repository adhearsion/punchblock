# encoding: utf-8

module Punchblock
  class Event
    class Answered < Event
      register :answered, :core

      include HasHeaders
    end
  end
end
