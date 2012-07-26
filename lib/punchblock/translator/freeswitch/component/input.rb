# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Input < Component

          attr_reader :grammar, :buffer

          def setup
            @buffer = ""
          end

          def execute
            initial_timeout = @component_node.initial_timeout || -1
            @inter_digit_timeout = @component_node.inter_digit_timeout || -1

            raise OptionError, 'A grammar document is required.' unless @component_node.grammar
            raise OptionError, 'A mode value other than DTMF is unsupported on FreeSWITCH.' unless @component_node.mode == :dtmf
            raise OptionError, 'An initial timeout value that is negative (and not -1) is invalid.' unless initial_timeout >= -1
            raise OptionError, 'An inter-digit timeout value that is negative (and not -1) is invalid.' unless @inter_digit_timeout >= -1

            send_ref

            @grammar = @component_node.grammar.value.clone
            grammar.inline!
            grammar.tokenize!
            grammar.normalize_whitespace

            begin_initial_timer initial_timeout/1000 unless initial_timeout == -1

            component = current_actor
            @dtmf_handler_id = call.register_handler :es, :event_name => 'DTMF' do |event|
              component.process_dtmf! event[:dtmf_digit]
            end
          rescue OptionError => e
            with_error 'option error', e.message
          end

          def process_dtmf(digit)
            buffer << digit
            cancel_initial_timer
            case (match = grammar.match buffer.dup)
            when RubySpeech::GRXML::Match
              complete success_reason(match)
            when RubySpeech::GRXML::NoMatch
              complete Punchblock::Component::Input::Complete::NoMatch.new
            when RubySpeech::GRXML::PotentialMatch
              reset_inter_digit_timer
            end
          end

          def execute_command(command)
            case command
            when Punchblock::Component::Stop
              command.response = true
              complete Punchblock::Event::Complete::Stop.new
            else
              super
            end
          end

          private

          def begin_initial_timer(timeout)
            @initial_timer = after timeout do
              complete Punchblock::Component::Input::Complete::NoInput.new
            end
          end

          def cancel_initial_timer
            return unless instance_variable_defined?(:@initial_timer) && @initial_timer
            @initial_timer.cancel
            @initial_timer = nil
          end

          def reset_inter_digit_timer
            return if @inter_digit_timeout == -1
            @inter_digit_timer ||= begin
              after @inter_digit_timeout/1000 do
                complete Punchblock::Component::Input::Complete::NoMatch.new
              end
            end
            @inter_digit_timer.reset
          end

          def cancel_inter_digit_timer
            return unless instance_variable_defined?(:@inter_digit_timer) && @inter_digit_timer
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
            call.unregister_handler :es, @dtmf_handler_id if instance_variable_defined?(:@dtmf_handler_id)
            cancel_initial_timer
            cancel_inter_digit_timer
            send_complete_event reason
          end
        end
      end
    end
  end
end
