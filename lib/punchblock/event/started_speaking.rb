# encoding: utf-8

require 'punchblock/event/active_speaker'

module Punchblock
  class Event
    class StartedSpeaking < Event
      register :'started-speaking', :core

      include ActiveSpeaker
    end
  end
end
