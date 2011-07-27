module Punchblock
  module Protocol
    class Rayo
      module Command
        module Tropo
          class Ask < CommandNode
            register :ask, :ask

            ##
            # Create an ask message
            #
            # @param [Hash] options for asking/prompting a specific call
            # @option options [Choices, Hash] :choices to allow the user to input
            # @option options [Prompt, Hash, Optional] :prompt to play/read to the caller as the question
            # @option options [Symbol, Optional] :mode by which to accept input. Can be :speech, :dtmf or :any
            # @option options [Integer, Optional] :timeout to wait for user input
            # @option options [Boolean, Optional] :bargein wether or not to allow the caller to begin their response before the prompt finishes
            # @option options [String, Optional] :recognizer to use for speech recognition
            # @option options [String, Optional] :terminator by which to signal the end of input
            # @option options [Float, Optional] :min_confidence with which to consider a response acceptable
            #
            # @return [Rayo::Command::Ask] a formatted Rayo ask command
            #
            # @example
            #    ask :prompt      => {:text => 'Please enter your postal code.', :voice => 'simon'},
            #        :choices     => {:value => '[5 DIGITS]'},
            #        :timeout     => 30,
            #        :recognizer  => 'es-es'
            #
            #    returns:
            #      <ask xmlns="urn:xmpp:tropo:ask:1" timeout="30" recognizer="es-es">
            #        <prompt voice='simon'>Please enter your postal code.</prompt>
            #        <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
            #      </ask>
            #
            def self.new(options = {})
              super().tap do |new_node|
                options.each_pair { |k,v| new_node.send :"#{k}=", v }
              end
            end

            ##
            # @return [Boolean] wether or not to allow the caller to begin their response before the prompt finishes
            #
            def bargein
              read_attr(:bargein) == "true"
            end

            ##
            # @param [Boolean] bargein wether or not to allow the caller to begin their response before the prompt finishes
            #
            def bargein=(bargein)
              write_attr :bargein, bargein.to_s
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
            def timeout
              read_attr :timeout, :to_i
            end

            ##
            # @param [Integer] timeout to wait for user input
            #
            def timeout=(timeout)
              write_attr :timeout, timeout
            end

            ##
            # @return [Prompt] the prompt by which to introduce the question
            #
            def prompt
              Prompt.new find_first('//ns:prompt', :ns => self.registered_ns)
            end

            ##
            # @param [Hash] p
            # @option p [String] :text to read the caller via TTS as the question
            # @option p [String] :voice to use for speech synthesis
            # @option p [String] :url to an audio file to play as the question
            #
            def prompt=(p)
              remove_children :prompt
              p = Prompt.new(p) unless p.is_a?(Prompt)
              self << p
            end

            class Prompt < Say
              register :prompt, :ask
            end

            ##
            # @return [Choices] the choices available
            #
            def choices
              Choices.new find_first('ns:choices', :ns => self.class.registered_ns)
            end

            ##
            # @param [Hash] choices
            # @option choices [String] :content_type
            # @option choices [String] :value the choices available
            #
            def choices=(choices)
              remove_children :choices
              choices = Choices.new(choices) unless choices.is_a?(Choices)
              self << choices
            end

            def inspect_attributes # :nodoc:
              [:bargein, :min_confidence, :mode, :recognizer, :terminator, :timeout, :prompt, :choices] + super
            end

            class Choices < RayoNode
              ##
              # @param [Hash] options
              # @option options [String] :content_type
              # @option options [String] :value the choices available
              #
              def self.new(options = {})
                super(:choices).tap do |new_node|
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
                write_attr 'content-type', content_type || 'application/grammar+voxeo'
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
                  if content_type == 'application/grammar+grxml'
                    xml.cdata value
                  else
                    xml.text value
                  end
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

            ##
            # Creates an Rayo stop message for the current Ask
            #
            # @return [Rayo::Message] an Rayo stop message
            #
            # @example
            #    ask_obj.stop_action.to_xml
            #
            #    returns:
            #      <stop xmlns="urn:xmpp:tropo:ask:1"/>
            def stop_action
              Stop.new :command_id => command_id, :call_id => call_id
            end

            ##
            # Sends an Rayo stop message for the current Ask
            #
            def stop!
              raise InvalidActionError, "Cannot stop an Ask that is not executing." unless executing?
              connection.write call_id, stop_action, command_id
            end

            class Complete
              class Success < Rayo::Event::Complete::Reason
                register :success, :ask_complete

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

              class NoMatch < Rayo::Event::Complete::Reason
                register :nomatch, :ask_complete
              end

              class NoInput < Rayo::Event::Complete::Reason
                register :noinput, :ask_complete
              end
            end # Complete
          end # Ask
        end # Tropo
      end # Command
    end # Rayo
  end # Protocol
end # Punchblock
