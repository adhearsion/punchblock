# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class FliteOutput < TTSOutput
          private

          def renderer
            :flite
          end

          def document
            concatenated_render_doc.inner_text.to_s
          end
        end
      end
    end
  end
end
