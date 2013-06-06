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
  unjoined
  started_speaking
  stopped_speaking
}.each { |e| require "punchblock/event/#{e}"}
