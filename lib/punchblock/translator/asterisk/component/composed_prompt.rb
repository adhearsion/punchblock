# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        class ComposedPrompt < Component
          include StopByRedirect

          def execute
          end
        end
      end
    end
  end
end
