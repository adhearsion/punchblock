# encoding: utf-8

module Punchblock
  module Translator
    module InputComponent
      def execute
        validate

        component = current_actor
        @recognizer = DTMFRecognizer.new current_actor,
                                         @component_node.grammar.value,
                                         (@component_node.initial_timeout || -1),
                                         (@component_node.inter_digit_timeout || -1)

        send_ref

        @dtmf_handler_id = register_dtmf_event_handler
      rescue OptionError => e
        with_error 'option error', e.message
      end

      def process_dtmf(digit)
        @recognizer << digit
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

      def validate
        raise OptionError, 'A grammar document is required.' unless @component_node.grammar
        raise OptionError, 'A mode value other than DTMF is unsupported.' unless @component_node.mode == :dtmf
      end

      def success_reason(match)
        nlsml = RubySpeech::NLSML.draw do
          interpretation confidence: match.confidence do
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
