module Punchblock
  class Event < RayoNode
  end
end

%w{
  answered
  complete
  dtmf
  end
  joined
  offer
  ringing
  unjoined
}.each { |e| require "punchblock/event/#{e}"}
