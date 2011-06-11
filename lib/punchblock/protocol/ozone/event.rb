module Punchblock
  module Protocol
    module Ozone
      module Event
        extend ActiveSupport::Autoload

        autoload :Complete
        autoload :End
        autoload :Info
        autoload :Offer
      end
    end
  end
end
