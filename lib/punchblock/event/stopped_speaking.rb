# encoding: utf-8

require 'punchblock/event/active_speaker'

module Punchblock
  class Event
    class StoppedSpeaking < Event
      register :'stopped-speaking', :core

      include ActiveSpeaker
    end
  end
end
