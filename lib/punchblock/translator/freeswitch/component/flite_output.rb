# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class FliteOutput < TTSOutput
          private

          def document
            @component_node.render_document.value.inner_text.to_s
          end
        end
      end
    end
  end
end
