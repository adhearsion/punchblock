module Punchblock
  class Rayo
    module Event
      extend ActiveSupport::Autoload

      eager_autoload do
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

      ActiveSupport::Autoload.eager_autoload!
    end
  end
end
