module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          extend ActiveSupport::Autoload

          autoload :AGICommand
          autoload :AMIAction
          autoload :Output
        end
      end
    end
  end
end
