# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Output < AbstractOutput
          private

          def validate
            super
            raise OptionError, "A voice value is unsupported." if @component_node.voice
            filenames
          end

          def do_output
            playback "file_string://#{filenames.join('!')}"
          end

          def filenames
            @filenames ||= @component_node.ssml.children.map do |node|
              case node
              when RubySpeech::SSML::Audio
                node.src
              else
                raise
              end
            end.compact
          rescue
            raise UnrenderableDocError, 'The provided document could not be rendered.'
          end

          def playback(path)
            op = current_actor
            register_handler :es, :event_name => 'CHANNEL_EXECUTE_COMPLETE' do |event|
              op.send_complete_event! success_reason
            end
            application 'playback', path
          end
        end
      end
    end
  end
end
