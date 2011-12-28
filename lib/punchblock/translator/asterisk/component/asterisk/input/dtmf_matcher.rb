module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class Input
            class DTMFMatcher
              attr_reader :grammar, :buffer

              def initialize(grammar)
                raise ArgumentError, 'You must supply a DTMF grammar' unless grammar.mode == 'dtmf'
                @grammar = grammar
                @buffer = []
              end

              def <<(other)
                buffer << other
              end

              def match?
                # buffer.all? { |d| root_rule. }
              end

              def invalid?

              end

              def root_rule
                grammar.root_rule
              end
            end
          end
        end
      end
    end
  end
end
