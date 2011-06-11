module Punchblock
  module Protocol
    module Ozone
      module Command
        extend ActiveSupport::Autoload

        autoload :Accept
        autoload :Answer
        autoload :Ask
        autoload :Conference
        autoload :Dial
        autoload :Hangup
        autoload :Redirect
        autoload :Reject
        autoload :Say
        autoload :Transfer
      end
    end
  end
end
