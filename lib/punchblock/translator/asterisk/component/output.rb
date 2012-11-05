# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Output < Component
          include StopByRedirect

          UnrenderableDocError = Class.new OptionError

          def setup
            @media_engine = @call.translator.media_engine
          end

          def execute
            raise OptionError, 'An SSML document is required.' unless @component_node.ssml
            raise OptionError, 'An interrupt-on value of speech is unsupported.' if @component_node.interrupt_on == :speech

            [:start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
              raise OptionError, "A #{opt} value is unsupported on Asterisk." if @component_node.send opt
            end

            early = !@call.answered?

            output_component = current_actor

            case @media_engine
            when :asterisk, nil
              raise OptionError, "A voice value is unsupported on Asterisk." if @component_node.voice
              raise OptionError, 'Interrupt digits are not allowed with early media.' if early && @component_node.interrupt_on

              case @component_node.interrupt_on
              when :any, :dtmf
                interrupt = true
              end

              path = filenames.join '&'

              send_ref

              @call.send_progress if early

              if interrupt
                call.register_handler :ami, :name => 'DTMF' do |event|
                  output_component.stop_by_redirect Punchblock::Component::Output::Complete::Success.new if event['End'] == 'Yes'
                end
              end

              opts = early ? "#{path},noanswer" : path
              playback opts
            when :unimrcp
              send_ref
              @call.send_agi_action! 'EXEC MRCPSynth', escape_commas(escaped_doc), mrcpsynth_options do |complete_event|
                output_component.send_complete_event! success_reason
              end
            when :swift
              send_ref
              @call.send_agi_action! 'EXEC Swift', swift_doc do |complete_event|
                output_component.send_complete_event! success_reason
              end
            when :festival
              send_ref
              @call.send_agi_action! 'EXEC Festival', @component_node.ssml do |complete_event|
                output_component.send_complete_event! success_reason
              end
            end
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
            raise UnrenderableDocError, 'The provided document could not be rendered. See http://adhearsion.com/docs/common_problems#unrenderable-document-error for details.'
          end

          def playback(path)
            op = current_actor
            @call.send_agi_action! 'EXEC Playback', path do |complete_event|
              op.send_complete_event! success_reason
            end
          end

          def escaped_doc
            @component_node.ssml.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }
          end

          def escape_commas(text)
            text.gsub(/,/, '\\,')
          end

          def mrcpsynth_options
            [].tap do |opts|
              opts << 'i=any' if [:any, :dtmf].include? @component_node.interrupt_on
              opts << "v=#{@component_node.voice}" if @component_node.voice
            end.join '&'
          end

          def swift_doc
            doc = escaped_doc
            doc << "|1|1" if [:any, :dtmf].include? @component_node.interrupt_on
            doc.insert 0, "#{@component_node.voice}^" if @component_node.voice
            doc
          end

          def success_reason
            Punchblock::Component::Output::Complete::Success.new
          end
        end
      end
    end
  end
end
