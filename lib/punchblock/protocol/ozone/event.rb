module Punchblock
  module Protocol
    class Ozone
      module Event
        extend ActiveSupport::Autoload

        autoload :Answered
        autoload :Complete
        autoload :End
        autoload :Info
        autoload :Offer
        autoload :Ringing

        # FIXME: Force autoload events so they get registered properly
        [Event::Answered, Event::Complete, Event::End, Event::Info, Event::Offer, Event::Ringing]
      end
    end
  end
end
