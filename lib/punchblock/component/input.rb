# encoding: utf-8

module Punchblock
  module Component
    class Input < ComponentNode
      register :input, :input

      # @return [Integer] the amount of time in milliseconds that an input command will wait until considered that a silence becomes a NO-MATCH
      attribute :max_silence, Integer

      # @return [Float] Confidence with which to consider a response acceptable
      attribute :min_confidence, Float

      # @return [Symbol] mode by which to accept input. Can be :speech, :dtmf or :any
      attribute :mode, Symbol

      # @return [String] recognizer to use for speech recognition
      attribute :recognizer

      # @return [String] terminator by which to signal the end of input
      attribute :terminator

      # @return [Float] Indicates how sensitive the interpreter should be to loud versus quiet input. Higher values represent greater sensitivity.
      attribute :sensitivity, Float

      # @return [Integer] Indicates the amount of time preceding input which may expire before a timeout is triggered.
      attribute :initial_timeout, Integer

      # @return [Integer] Indicates (in the case of DTMF input) the amount of time between input digits which may expire before a timeout is triggered.
      attribute :inter_digit_timeout, Integer

      attribute :grammar
      def grammar=(other)
        return if other.nil?
        super Grammar.new(other)
      end

      def inherit(xml_node)
        grammar_node = xml_node.at_xpath('ns:grammar', ns: self.class.registered_ns)
        self.grammar = Grammar.from_xml(grammar_node) if grammar_node
        super
      end

      def rayo_attributes
        {
          'max-silence' => max_silence,
          'min-confidence' => min_confidence,
          'mode' => mode,
          'recognizer' => recognizer,
          'terminator' => terminator,
          'sensitivity' => sensitivity,
          'initial-timeout' => initial_timeout,
          'inter-digit-timeout' => inter_digit_timeout
        }
      end

      def rayo_children(root)
        if grammar
          root.grammar(grammar.rayo_attributes.delete_if { |k,v| v.nil? }) do |xml|
            xml.cdata grammar.value
          end
        end
        super
      end

      class Grammar < RayoNode
        register :grammar, :input

        GRXML_CONTENT_TYPE = 'application/srgs+xml'

        attribute :value
        attribute :content_type, String, default: ->(grammar, attribute) { grammar.url ? nil : GRXML_CONTENT_TYPE }
        attribute :url

        def inherit(xml_node)
          self.value = xml_node.content.strip
          super
        end

        def rayo_attributes
          {}.tap do |atts|
            atts['url'] = url
            atts['content-type'] = content_type
          end
        end

        private

        def grxml?
          content_type == GRXML_CONTENT_TYPE
        end
      end

      class Complete
        class Success < Event::Complete::Reason
          register :success, :input_complete

          attribute :mode, Symbol
          attribute :confidence, Float
          attribute :utterance
          attribute :interpretation

          def inherit(xml_node)
            self.utterance = xml_node.at_xpath('ns:utterance', ns: self.class.registered_ns).content
            self.interpretation = xml_node.at_xpath('ns:interpretation', ns: self.class.registered_ns).content
            super
          end
        end

        class NoMatch < Event::Complete::Reason
          register :nomatch, :input_complete
        end

        class NoInput < Event::Complete::Reason
          register :noinput, :input_complete
        end
      end
    end
  end
end
