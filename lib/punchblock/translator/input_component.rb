# encoding: utf-8

module Punchblock
  module Translator
    module InputComponent
      def execute
        validate
        setup_dtmf_recognizer
        send_ref
        start_timers
      rescue OptionError, ArgumentError => e
        with_error 'option error', e.message
      end

      def process_dtmf(digit)
        begin
          @recognizer << digit
        rescue Celluloid::DeadActorError => e
          pb_logger.error "Called a dead actor while processing a dtmf digit"
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

      def match(match)
        complete success_reason(match)
      end

      def nomatch
        complete Punchblock::Component::Input::Complete::NoMatch.new
      end

      def noinput
        complete Punchblock::Component::Input::Complete::NoInput.new
      end

      private

      def input_node
        @component_node
      end

      def validate
        raise OptionError, 'A grammar document is required.' unless input_node.grammars.first
        raise OptionError, 'Only a single grammar is supported.' unless input_node.grammars.size == 1
        raise OptionError, 'A mode value other than DTMF is unsupported.' unless input_node.mode == :dtmf
      end

      def setup_dtmf_recognizer
        @recognizer = DTMFRecognizer.new self,
                        input_node.grammars.first,
                        (input_node.initial_timeout || -1),
                        (input_node.inter_digit_timeout || -1),
                        input_node.terminator
      end

      def start_timers
        @recognizer.start_timers
      end

      def success_reason(match)
        nlsml = RubySpeech::NLSML.draw do
          interpretation confidence: match.confidence do
            instance match.interpretation
            input match.utterance, mode: match.mode
          end
        end
        Punchblock::Component::Input::Complete::Match.new :nlsml => nlsml
      end

      def complete(reason)
        unregister_dtmf_event_handler
        send_complete_event reason
      end
    end
  end
end
