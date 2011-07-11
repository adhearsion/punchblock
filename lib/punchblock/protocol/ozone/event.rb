module Punchblock
  module Protocol
    class Ozone
      module Event
        extend ActiveSupport::Autoload

        autoload :Answered
        autoload :Complete
        autoload :DTMF
        autoload :End
        autoload :Info
        autoload :Offer
        autoload :Ringing
      end
    end
  end
end
