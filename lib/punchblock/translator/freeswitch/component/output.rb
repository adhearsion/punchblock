# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Output < Component
          UnrenderableDocError = Class.new OptionError

          def execute
            validate

            send_ref

            playback filenames.join('&')
          rescue UnrenderableDocError => e
            with_error 'unrenderable document error', e.message
          rescue OptionError => e
            with_error 'option error', e.message
          end

          private

          def validate
            raise OptionError, 'An SSML document is required.' unless @component_node.ssml

            [:start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time, :voice].each do |opt|
              raise OptionError, "A #{opt} value is unsupported." if @component_node.send opt
            end

            case @component_node.interrupt_on
            when :speech, :dtmf, :any
              raise OptionError, "An interrupt-on value of #{@component_node.interrupt_on} is unsupported."
            end

            filenames
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

          def success_reason
            Punchblock::Component::Output::Complete::Success.new
          end
        end
      end
    end
  end
end
