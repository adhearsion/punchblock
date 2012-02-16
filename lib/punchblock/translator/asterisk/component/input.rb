module Punchblock
  module Translator
    class Asterisk
      module Component
        class Input < Component

          attr_reader :grammar, :buffer

          def setup
            @media_engine = call.translator.media_engine
            @buffer       = ""
          end

          def execute
            @call.answer_if_not_answered
            initial_timeout = @component_node.initial_timeout || -1
            @inter_digit_timeout = @component_node.inter_digit_timeout || -1

            return with_error 'option error', 'A grammar document is required.' unless @component_node.grammar
            return with_error 'option error', 'A mode value other than DTMF is unsupported on Asterisk.' unless @component_node.mode == :dtmf
            return with_error 'option error', 'An initial timeout value that is negative (and not -1) is invalid.' unless initial_timeout >= -1
            return with_error 'option error', 'An inter-digit timeout value that is negative (and not -1) is invalid.' unless @inter_digit_timeout >= -1

            send_ref

            case @media_engine
            when :asterisk, nil
              @grammar = @component_node.grammar.value.clone
              grammar.inline!
              grammar.tokenize!
              grammar.normalize_whitespace

              begin_initial_timer initial_timeout/1000 unless initial_timeout == -1

              component = current_actor

              @active = true

              call.register_handler :ami, :name => 'DTMF' do |event|
                component.process_dtmf! event['Digit'] if event['End'] == 'Yes'
              end
            end
          end

          def process_dtmf(digit)
            return unless @active
            pb_logger.trace "Processing incoming DTMF digit #{digit}"
            buffer << digit
            cancel_initial_timer
            case (match = grammar.match buffer.dup)
            when RubySpeech::GRXML::Match
              pb_logger.trace "Found a match against buffer #{buffer}"
              complete success_reason(match)
            when RubySpeech::GRXML::NoMatch
              pb_logger.trace "Buffer #{buffer} does not match grammar"
              complete Punchblock::Component::Input::Complete::NoMatch.new
            when RubySpeech::GRXML::PotentialMatch
              pb_logger.trace "Buffer #{buffer} potentially matches grammar. Waiting..."
              reset_inter_digit_timer
            end
          end

          private

          def begin_initial_timer(timeout)
            pb_logger.trace "Setting initial timer for #{timeout} seconds"
            @initial_timer = after timeout do
              pb_logger.trace "Initial timer expired."
              complete Punchblock::Component::Input::Complete::NoInput.new
            end
          end

          def cancel_initial_timer
            return unless @initial_timer
            @initial_timer.cancel
            @initial_timer = nil
          end

          def reset_inter_digit_timer
            return if @inter_digit_timeout == -1
            @inter_digit_timer ||= begin
              pb_logger.trace "Setting inter-digit timer for #{@inter_digit_timeout/1000} seconds"
              after @inter_digit_timeout/1000 do
                pb_logger.trace "Inter digit-timer expired."
                complete Punchblock::Component::Input::Complete::NoMatch.new
              end
            end
            pb_logger.trace "Resetting inter-digit timer"
            @inter_digit_timer.reset
          end

          def cancel_inter_digit_timer
            return unless @inter_digit_timer
            @inter_digit_timer.cancel
            @inter_digit_timer = nil
          end

          def success_reason(match)
            Punchblock::Component::Input::Complete::Success.new :mode           => match.mode,
                                                                :confidence     => match.confidence,
                                                                :utterance      => match.utterance,
                                                                :interpretation => match.interpretation
          end

          def complete(reason)
            @active = false
            cancel_initial_timer
            cancel_inter_digit_timer
            send_complete_event reason
          end
        end
      end
    end
  end
end
