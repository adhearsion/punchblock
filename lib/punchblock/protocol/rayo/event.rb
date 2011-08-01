module Punchblock
  module Protocol
    class Rayo
      module Event
        extend ActiveSupport::Autoload

        autoload :Answered
        autoload :Complete
        autoload :DTMF
        autoload :End
        autoload :Info
        autoload :Joined
        autoload :Offer
        autoload :Ringing
        autoload :Unjoined
      end
    end
  end
end
