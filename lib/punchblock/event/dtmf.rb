# encoding: utf-8

module Punchblock
  class Event
    class DTMF < Event
      register :dtmf, :core

      attribute :signal
    end
  end
end
