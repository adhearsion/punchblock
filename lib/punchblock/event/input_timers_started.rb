# encoding: utf-8

module Punchblock
  class Event
    class InputTimersStarted < Event
      register :'input-timers-started', :prompt
    end
  end
end
