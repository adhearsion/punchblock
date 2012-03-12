# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Output < Component

          def setup
            @media_engine = @call.translator.media_engine
          end

          def execute
            @call.answer_if_not_answered

            return with_error 'option error', 'An SSML document is required.' unless @component_node.ssml

            return with_error 'option error', 'An interrupt-on value of speech is unsupported.' if @component_node.interrupt_on == :speech

            [:start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
              return with_error 'option error', "A #{opt} value is unsupported on Asterisk." if @component_node.send opt
            end

            case @media_engine
            when :asterisk, nil
              return with_error 'option error', "A voice value is unsupported on Asterisk." if @component_node.voice

              @execution_elements = @component_node.ssml.children.map do |node|
                case node
                when RubySpeech::SSML::Audio
                  lambda { current_actor.play_audio! node.src }
                else
                  return with_error 'unrenderable document error', 'The provided document could not be rendered.'
                end
              end.compact

              @pending_actions = @execution_elements.count

              send_ref

              @interrupt_digits = '0123456789*#' if [:any, :dtmf].include? @component_node.interrupt_on

              @execution_elements.each do |element|
                element.call
                wait :continue
                process_playback_completion
              end
            when :unimrcp
              send_ref
              @call.send_agi_action! 'EXEC MRCPSynth', escaped_doc, mrcpsynth_options do |complete_event|
                pb_logger.debug "MRCPSynth completed with #{complete_event}."
                send_complete_event success_reason
              end
            when :swift
              doc = escaped_doc
              doc << "|1|1" if [:any, :dtmf].include? @component_node.interrupt_on
              doc.insert 0, "#{@component_node.voice}^" if @component_node.voice
              send_ref
              @call.send_agi_action! 'EXEC Swift', doc do |complete_event|
                pb_logger.debug "Swift completed with #{complete_event}."
                send_complete_event success_reason
              end
            end
          end

          def process_playback_completion
            @pending_actions -= 1
            pb_logger.debug "Received action completion. Now waiting on #{@pending_actions} actions."
            if @pending_actions < 1
              pb_logger.debug "Sending complete event"
              send_complete_event success_reason
            end
          end

          def continue(event = nil)
            signal :continue, event
          end

          def play_audio(path)
            pb_logger.debug "Playing an audio file (#{path}) via STREAM FILE"
            op = current_actor
            @call.send_agi_action! 'STREAM FILE', path, @interrupt_digits do |complete_event|
              pb_logger.debug "STREAM FILE completed with #{complete_event}. Signalling to continue execution."
              op.continue! complete_event
            end
          end

          private

          def escaped_doc
            @component_node.ssml.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }
          end

          def mrcpsynth_options
            [].tap do |opts|
              opts << 'i=any' if [:any, :dtmf].include? @component_node.interrupt_on
              opts << "v=#{@component_node.voice}" if @component_node.voice
            end.join '&'
          end

          def success_reason
            Punchblock::Component::Output::Complete::Success.new
          end
        end
      end
    end
  end
end
