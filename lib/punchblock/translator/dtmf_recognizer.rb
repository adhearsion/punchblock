# encoding: utf-8

module Punchblock
  module Translator
    class DTMFRecognizer
      include Celluloid

      def initialize(responder, grammar, initial_timeout = nil, inter_digit_timeout = nil)
        @responder = responder
        self.grammar = grammar
        self.initial_timeout = initial_timeout || -1
        self.inter_digit_timeout = inter_digit_timeout || -1

        @buffer = ""

        begin_initial_timer @initial_timeout/1000 unless @initial_timeout == -1
      end

      def <<(digit)
        @buffer << digit
        cancel_initial_timer
        case (match = @grammar.match @buffer.dup)
        when RubySpeech::GRXML::Match
          @responder.match match.mode, match.confidence, match.utterance, match.interpretation
        when RubySpeech::GRXML::NoMatch
          @responder.nomatch
        when RubySpeech::GRXML::PotentialMatch
          reset_inter_digit_timer
        end
      end

      def finalize
        cancel_initial_timer
        cancel_inter_digit_timer
      end

      private

      def grammar=(other)
        @grammar = RubySpeech::GRXML.import other.to_s
        @grammar.inline!
        @grammar.tokenize!
        @grammar.normalize_whitespace
      end

      def initial_timeout=(other)
        raise OptionError, 'An initial timeout value that is negative (and not -1) is invalid.' unless other >= -1
        @initial_timeout = other
      end

      def inter_digit_timeout=(other)
        raise OptionError, 'An inter-digit timeout value that is negative (and not -1) is invalid.' unless other >= -1
        @inter_digit_timeout = other
      end

      def begin_initial_timer(timeout)
        @initial_timer = after timeout do
          @responder.noinput
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
            @responder.nomatch
          end
        end
        @inter_digit_timer.reset
      end

      def cancel_inter_digit_timer
        return unless instance_variable_defined?(:@inter_digit_timer) && @inter_digit_timer
        @inter_digit_timer.cancel
        @inter_digit_timer = nil
      end
    end
  end
end
