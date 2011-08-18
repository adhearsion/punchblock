%w{
  answered
  complete
  dtmf
  end
  info
  joined
  offer
  ringing
  unjoined
}.each { |e| require "punchblock/rayo/event/#{e}"}
