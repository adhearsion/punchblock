module Punchblock
  module Translator
    class Asterisk
      module Component
        extend ActiveSupport::Autoload

        autoload :Asterisk

        class Component
          include Celluloid

          attr_reader :id
        end
      end
    end
  end
end
