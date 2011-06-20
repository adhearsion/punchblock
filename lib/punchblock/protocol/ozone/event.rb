module Punchblock
  module Protocol
    class Ozone
      module Event
        extend ActiveSupport::Autoload

        autoload :Complete
        autoload :End
        autoload :Info
        autoload :Offer

        # FIXME: Force autoload events so they get registered properly
        [Event::Complete, Event::End, Event::Info, Event::Offer]
      end
    end
  end
end
