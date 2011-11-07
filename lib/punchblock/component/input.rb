module Punchblock
  module Component
    class Input < ComponentNode
      register :input, :input

      ##
      # Create an input message
      #
      # @param [Hash] options for inputing/prompting a specific call
      # @option options [Choices, Hash] :choices to allow the user to input
      # @option options [Prompt, Hash, Optional] :prompt to play/read to the caller as the question
      # @option options [Symbol, Optional] :mode by which to accept input. Can be :speech, :dtmf or :any
      # @option options [Integer, Optional] :timeout to wait for user input
      # @option options [Boolean, Optional] :bargein wether or not to allow the caller to begin their response before the prompt finishes
      # @option options [String, Optional] :recognizer to use for speech recognition
      # @option options [String, Optional] :terminator by which to signal the end of input
      # @option options [Float, Optional] :min_confidence with which to consider a response acceptable
      #
      # @return [Command::Input] a formatted Rayo input command
      #
      # @example
      #    input :prompt      => {:text => 'Please enter your postal code.', :voice => 'simon'},
      #          :choices     => {:value => '[5 DIGITS]'},
      #          :timeout     => 30,
      #          :recognizer  => 'es-es'
      #
      #    returns:
      #      <input xmlns="urn:xmpp:tropo:input:1" timeout="30" recognizer="es-es">
      #        <prompt voice='simon'>Please enter your postal code.</prompt>
      #        <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
      #      </input>
      #
      def self.new(options = {})
        super().tap do |new_node|
          options.each_pair { |k,v| new_node.send :"#{k}=", v }
        end
      end

      ##
      # @return [Boolean] wether or not to allow the caller to begin their response before the prompt finishes
      #
      def max_digits
        read_attr :'max-digits', :to_i
      end

      ##
      # @param [Boolean] bargein wether or not to allow the caller to begin their response before the prompt finishes
      #
      def max_digits=(other)
        write_attr :'max-digits', other
      end

      ##
      # @return [Float] Confidence with which to consider a response acceptable
      #
      def min_confidence
        read_attr 'min-confidence', :to_f
      end

      ##
      # @param [Float] min_confidence with which to consider a response acceptable
      #
      def min_confidence=(min_confidence)
        write_attr 'min-confidence', min_confidence
      end

      ##
      # @return [Symbol] mode by which to accept input. Can be :speech, :dtmf or :any
      #
      def mode
        read_attr :mode, :to_sym
      end

      ##
      # @param [Symbol] mode by which to accept input. Can be :speech, :dtmf or :any
      #
      def mode=(mode)
        write_attr :mode, mode
      end

      ##
      # @return [String] recognizer to use for speech recognition
      #
      def recognizer
        read_attr :recognizer
      end

      ##
      # @param [String] recognizer to use for speech recognition
      #
      def recognizer=(recognizer)
        write_attr :recognizer, recognizer
      end

      ##
      # @return [String] terminator by which to signal the end of input
      #
      def terminator
        read_attr :terminator
      end

      ##
      # @param [String] terminator by which to signal the end of input
      #
      def terminator=(terminator)
        write_attr :terminator, terminator
      end

      ##
      # @return [Integer] timeout to wait for user input
      #
      def sensitivity
        read_attr :sensitivity, :to_f
      end

      ##
      # @param [Integer] timeout to wait for user input
      #
      def sensitivity=(other)
        write_attr :sensitivity, other
      end

      ##
      # @return [Integer] timeout to wait for user input
      #
      def initial_timeout
        read_attr :'initial-timeout', :to_i
      end

      ##
      # @param [Integer] timeout to wait for user input
      #
      def initial_timeout=(other)
        write_attr :'initial-timeout', other
      end

      ##
      # @return [Integer] timeout to wait for user input
      #
      def inter_digit_timeout
        read_attr :'inter-digit-timeout', :to_i
      end

      ##
      # @param [Integer] timeout to wait for user input
      #
      def inter_digit_timeout=(other)
        write_attr :'inter-digit-timeout', other
      end

      ##
      # @return [Integer] timeout to wait for user input
      #
      def term_timeout
        read_attr :'term-timeout', :to_i
      end

      ##
      # @param [Integer] timeout to wait for user input
      #
      def term_timeout=(other)
        write_attr :'term-timeout', other
      end

      ##
      # @return [Integer] timeout to wait for user input
      #
      def complete_timeout
        read_attr :'complete-timeout', :to_i
      end

      ##
      # @param [Integer] timeout to wait for user input
      #
      def complete_timeout=(other)
        write_attr :'complete-timeout', other
      end

      ##
      # @return [Integer] timeout to wait for user input
      #
      def incomplete_timeout
        read_attr :'incomplete-timeout', :to_i
      end

      ##
      # @param [Integer] timeout to wait for user input
      #
      def incomplete_timeout=(other)
        write_attr :'incomplete-timeout', other
      end

      ##
      # @return [Choices] the choices available
      #
      def grammar
        Grammar.new find_first('ns:grammar', :ns => self.class.registered_ns)
      end

      ##
      # @param [Hash] choices
      # @option choices [String] :content_type
      # @option choices [String] :value the choices available
      #
      def grammar=(other)
        remove_children :grammar
        grammar = Grammar.new(other) unless other.is_a?(Grammar)
        self << grammar
      end

      def inspect_attributes # :nodoc:
        [:mode, :terminator, :max_digits, :recognizer, :initial_timeout, :inter_digit_timeout, :term_timeout, :complete_timeout, :incomplete_timeout, :sensitivity, :min_confidence, :choices] + super
      end

      class Grammar < RayoNode
        ##
        # @param [Hash] options
        # @option options [String] :content_type
        # @option options [String] :value the choices available
        #
        def self.new(options = {})
          super(:grammar).tap do |new_node|
            case options
            when Nokogiri::XML::Node
              new_node.inherit options
            when Hash
              new_node.content_type = options[:content_type]
              new_node.value = options[:value]
            end
          end
        end

        ##
        # @return [String] the choice content type
        #
        def content_type
          read_attr 'content-type'
        end

        ##
        # @param [String] content_type Defaults to the Voxeo Simple Grammar
        #
        def content_type=(content_type)
          write_attr 'content-type', content_type || 'application/grammar+grxml'
        end

        ##
        # @return [String] the choices available
        def value
          content
        end

        ##
        # @param [String] value the choices available
        def value=(value)
          Nokogiri::XML::Builder.with(self) do |xml|
            xml.cdata " #{value} "
          end
        end

        # Compare two Choices objects by content type, and value
        # @param [Header] o the Choices object to compare against
        # @return [true, false]
        def eql?(o, *fields)
          super o, *(fields + [:content_type, :value])
        end

        def inspect_attributes # :nodoc:
          [:content_type, :value] + super
        end
      end # Choices

      class Complete
        class Success < Event::Complete::Reason
          register :success, :input_complete

          ##
          # @return [Symbol] the mode by which the question was answered. May be :speech or :dtmf
          #
          def mode
            read_attr :mode, :to_sym
          end

          ##
          # @return [Float] A measure of the confidence of the result, between 0-1
          #
          def confidence
            read_attr :confidence, :to_f
          end

          ##
          # @return [String] An intelligent interpretation of the meaning of the response.
          #
          def interpretation
            find_first('//ns:interpretation', :ns => self.registered_ns).text
          end

          ##
          # @return [String] The exact response gained
          #
          def utterance
            find_first('//ns:utterance', :ns => self.registered_ns).text
          end

          def inspect_attributes # :nodoc:
            [:mode, :confidence, :interpretation, :utterance] + super
          end
        end

        class NoMatch < Event::Complete::Reason
          register :nomatch, :input_complete
        end

        class NoInput < Event::Complete::Reason
          register :noinput, :input_complete
        end
      end # Complete
    end # Input
  end # Component
end # Punchblock
