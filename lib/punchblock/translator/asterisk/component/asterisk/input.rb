module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class Input < Component

            attr_reader :grammar, :buffer

            def setup
              @media_engine = call.translator.media_engine
              @buffer       = ""
            end

            def execute
              return with_error 'option error', 'A grammar document is required.' unless @component_node.grammar
              return with_error 'option error', 'A mode value other than DTMF is unsupported on Asterisk.' unless @component_node.mode == :dtmf

              send_ref

              case @media_engine
              when :asterisk, nil
                @grammar = @component_node.grammar.value.clone
                grammar.inline!
                grammar.tokenize!
                grammar.normalize_whitespace

                component = current_actor

                call.register_handler :ami, :name => 'DTMF' do |event|
                  component.process_dtmf! event['Digit'] if event['End'] == 'Yes'
                end
              end
            end

            def process_dtmf(digit)
              pb_logger.trace "Processing incoming DTMF digit #{digit}"
              buffer << digit
              case (match = grammar.match buffer.dup)
              when RubySpeech::GRXML::Match
                pb_logger.trace "Found a match against buffer #{buffer}"
                send_event complete_event(success_reason(match))
              when RubySpeech::GRXML::NoMatch
                pb_logger.trace "Buffer #{buffer} does not match grammar"
                send_event complete_event(nomatch_reason)
              when RubySpeech::GRXML::PotentialMatch
                pb_logger.trace "Buffer #{buffer} potentially matches grammar. Waiting..."
              end
            end

            private

            def success_reason(match)
              Punchblock::Component::Input::Complete::Success.new :mode           => match.mode,
                                                                  :confidence     => match.confidence,
                                                                  :utterance      => match.utterance,
                                                                  :interpretation => match.interpretation
            end

            def nomatch_reason
              Punchblock::Component::Input::Complete::NoMatch.new
            end
          end
        end
      end
    end
  end
end
