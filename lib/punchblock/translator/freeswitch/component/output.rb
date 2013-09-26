# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Output < AbstractOutput
          private

          def validate
            super
            filenames
          end

          def do_output
            playback "file_string://#{filenames.join('!')}"
          end

          def filenames
            @filenames ||= @component_node.render_documents.map do |doc|
              doc.value.children.map do |node|
                case node
                when RubySpeech::SSML::Audio
                  node.src
                when String
                  raise if node.include?(' ')
                  node
                else
                  raise
                end
              end
            end.compact.flatten
          rescue
            raise UnrenderableDocError, 'The provided document could not be rendered. See http://adhearsion.com/docs/common_problems#unrenderable-document-error for details.'
          end

          def playback(path)
            register_handler :es, :event_name => 'CHANNEL_EXECUTE_COMPLETE' do |event|
              send_complete_event complete_reason_for_event(event)
            end
            application 'playback', path
          end

          def complete_reason_for_event(event)
            case event[:application_response]
            when 'FILE PLAYED'
              finish_reason
            else
              Punchblock::Event::Complete::Error.new(:details => "Engine error: #{event[:application_response]}")
            end
          end
        end
      end
    end
  end
end
