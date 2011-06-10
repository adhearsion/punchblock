require 'punchblock/protocol/ozone/say'

module Punchblock
  module Protocol
    module Ozone
      class Ask < Command
        register :ask, :ask

        ##
        # Create an ask message
        #
        # @param [String] prompt to ask the caller
        # @param [String] choices to ask the user
        # @param [Hash] options for asking/prompting a specific call
        # @option options [Symbol, Optional] :mode by which to accept input. Can be :speech, :dtmf or :any
        # @option options [Integer, Optional] :response_timeout to wait for user input
        # @option options [String, Optional] :recognizer to use for speech recognition
        # @option options [String, Optional] :voice to use for speech synthesis
        # @option options [String, Optional] :terminator by which to signal the end of input
        # @option options [Float, Optional] :min_confidence with which to consider a response acceptable
        # @option options [String or Nokogiri::XML, Optional] :grammar to use for speech recognition (ie - application/grammar+voxeo or application/grammar+grxml)
        #
        # @return [Ozone::Message] a formatted Ozone ask message
        #
        # @example
        #    ask 'Please enter your postal code.',
        #        '[5 DIGITS]',
        #        :timeout => 30,
        #        :recognizer => 'es-es',
        #        :voice => 'simon'
        #
        #    returns:
        #      <ask xmlns="urn:xmpp:ozone:ask:1" timeout="30" recognizer="es-es">
        #        <prompt voice='simon'>Please enter your postal code.</prompt>
        #        <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
        #      </ask>
        def self.new(prompt = '', options = {})
          super().tap do |new_node|
            new_node.prompt = {:text => prompt, :voice => options.delete(:voice), :url => options.delete(:url)}
            new_node.choices = {:content_type => options.delete(:grammar), :value => options.delete(:choices)}

            options.each_pair { |k,v| new_node.send :"#{k}=", v }
          end
        end

        def bargein
          read_attr(:bargein) == "true"
        end

        def bargein=(bargein)
          write_attr :bargein, bargein.to_s
        end

        def min_confidence
          read_attr 'min-confidence', :to_f
        end

        def min_confidence=(min_confidence)
          write_attr 'min-confidence', min_confidence
        end

        def mode
          read_attr :mode, :to_sym
        end

        def mode=(mode)
          write_attr :mode, mode
        end

        def recognizer
          read_attr :recognizer
        end

        def recognizer=(recognizer)
          write_attr :recognizer, recognizer
        end

        def terminator
          read_attr :terminator
        end

        def terminator=(terminator)
          write_attr :terminator, terminator
        end

        def timeout
          read_attr :timeout, :to_i
        end

        def timeout=(rt)
          write_attr :timeout, rt
        end

        def prompt
          Prompt.new find_first('//ns:prompt', :ns => self.registered_ns)
        end

        def prompt=(p)
          self << Prompt.new(p)
        end

        class Prompt < Say
          register :prompt, :ask
        end

        def choices
          Choices.new find_first('ns:choices', :ns => self.class.registered_ns)
        end

        def choices=(choices)
          remove_children :choices
          self << Choices.new(choices)
        end

        def attributes
          [:bargein, :min_confidence, :mode, :recognizer, :terminator, :timeout, :prompt, :choices] + super
        end

        class Choices < OzoneNode
          def self.new(value, content_type = 'application/grammar+voxeo')
            # Default is the Voxeo Simple Grammar, unless specified

            super(:choices).tap do |new_node|
              case value
              when Nokogiri::XML::Node
                new_node.inherit value
              when Hash
                new_node.content_type = value[:content_type]
                new_node.value = value[:value]
              else
                new_node.content_type = content_type
                new_node.value = value
              end
            end
          end

          # The Header's name
          # @return [Symbol]
          def content_type
            read_attr 'content-type'
          end

          # Set the Header's name
          # @param [Symbol] name the new name for the header
          def content_type=(content_type)
            write_attr 'content-type', content_type
          end

          # The Header's value
          # @return [String]
          def value
            content
          end

          # Set the Header's value
          # @param [String] value the new value for the header
          def value=(value)
            Nokogiri::XML::Builder.with(self) do |xml|
              if content_type == 'application/grammar+grxml'
                xml.cdata value
              else
                xml.text value
              end
            end
          end

          # Compare two Header objects by name, and value
          # @param [Header] o the Header object to compare against
          # @return [true, false]
          def eql?(o, *fields)
            super o, *(fields + [:content_type])
          end

          def attributes
            [:content_type, :value] + super
          end
        end

        class Complete
          class Success < Ozone::Complete::Reason
            register :success, :ask_complete

            def mode
              read_attr :mode, :to_sym
            end

            def confidence
              read_attr :confidence, :to_f
            end

            def interpretation
              find_first('//ns:interpretation', :ns => self.registered_ns).text
            end

            def utterance
              find_first('//ns:utterance', :ns => self.registered_ns).text
            end

            def attributes
              [:mode, :confidence, :interpretation, :utterance] + super
            end
          end

          class NoMatch < Ozone::Complete::Reason
            register :nomatch, :ask_complete
          end

          class NoInput < Ozone::Complete::Reason
            register :noinput, :ask_complete
          end
        end
      end # Ask
    end # Ozone
  end # Protocol
end # Punchblock
