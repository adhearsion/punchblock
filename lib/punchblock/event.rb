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
  info
  joined
  offer
  ringing
  unjoined
}.each { |e| require "punchblock/event/#{e}"}
