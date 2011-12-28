module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class Input < Component
            extend ActiveSupport::Autoload

            autoload :DTMFMatcher

            attr_reader :matcher

            def setup
              @media_engine = @call.translator.media_engine
            end

            def execute
              return with_error 'option error', 'A grammar document is required.' unless @component_node.grammar
              return with_error 'option error', 'A mode value other than DTMF is unsupported on Asterisk.' unless @component_node.mode == :dtmf

              send_ref

              case @media_engine
              when :asterisk, nil
                @matcher = DTMFMatcher.new @component_node.grammar.value
              end
            end

            private

            def on_match
              send_event complete_event(success_reason)
            end

            def success_reason
              Punchblock::Component::Input::Complete::Success.new
            end
          end
        end
      end
    end
  end
end
