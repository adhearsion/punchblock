# encoding: utf-8

module Punchblock
  class Event < RayoNode
  end
end

%w{
  answered
  asterisk
  complete
  dtmf
  end
  joined
  offer
  ringing
  input_timers_started
  unjoined
  started_speaking
  stopped_speaking
}.each { |e| require "punchblock/event/#{e}"}
