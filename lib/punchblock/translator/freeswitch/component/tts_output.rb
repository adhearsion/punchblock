# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class TTSOutput < AbstractOutput
          private

          def do_output
            register_handler :es, :event_name => 'CHANNEL_EXECUTE_COMPLETE' do |event|
              send_complete_event finish_reason
            end
            voice = @component_node.voice || :kal
            application :speak, [renderer, voice, document].join('|')
          end

          def renderer
            @component_node.renderer || :flite
          end

          def document
            @component_node.render_documents.first.value.to_s
          end
        end
      end
    end
  end
end
