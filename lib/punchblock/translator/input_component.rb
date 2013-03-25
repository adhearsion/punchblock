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

      def match(mode, confidence, utterance, interpretation)
        complete Punchblock::Component::Input::Complete::Success.new(:mode => mode, :confidence => confidence, :utterance => utterance, :interpretation => interpretation)
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

      def complete(reason)
        unregister_dtmf_event_handler
        send_complete_event reason
      end
    end
  end
end
