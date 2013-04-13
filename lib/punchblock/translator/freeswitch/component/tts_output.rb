# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class TTSOutput < AbstractOutput
          private

          def do_output(engine, default_voice = nil)
            register_handler :es, :event_name => 'CHANNEL_EXECUTE_COMPLETE' do |event|
              send_complete_event success_reason
            end
            voice = @component_node.voice || default_voice || 'kal'
            application :speak, [engine, voice, document].join('|')
          end

          def document
            @component_node.ssml.to_s
          end
        end
      end
    end
  end
end
