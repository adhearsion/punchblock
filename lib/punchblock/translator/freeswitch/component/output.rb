# encoding: utf-8

# require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Output < Component
          UnrenderableDocError = Class.new OptionError

          def execute
            raise OptionError, 'An SSML document is required.' unless @component_node.ssml
            # raise OptionError, 'An interrupt-on value of speech is unsupported.' if @component_node.interrupt_on == :speech

            # [:start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
            #   raise OptionError, "A #{opt} value is unsupported on Asterisk." if @component_node.send opt
            # end

            # early = !@call.answered?

            # raise OptionError, "A voice value is unsupported on Asterisk." if @component_node.voice
            # raise OptionError, 'Interrupt digits are not allowed with early media.' if early && @component_node.interrupt_on

            # case @component_node.interrupt_on
            # when :dtmf, :any
            #   raise OptionError, "An interrupt-on value of #{@component_node.interrupt_on} is unsupported."
            # end

            path = filenames.join '&'

            send_ref

            # @call.send_progress if early

            # opts = early ? "#{path},noanswer" : path
            playback path
          rescue UnrenderableDocError => e
            with_error 'unrenderable document error', e.message
          rescue OptionError => e
            with_error 'option error', e.message
          end

          private

          def filenames
            @filenames ||= @component_node.ssml.children.map do |node|
              case node
              when RubySpeech::SSML::Audio
                node.src
              when String
                raise if node.include?(' ')
                node
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
