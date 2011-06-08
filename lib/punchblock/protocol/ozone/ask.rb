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
          new_node = super()

          voice = options.delete :voice
          grammar_type = options.delete(:grammar) || 'application/grammar+voxeo' # Default is the Voxeo Simple Grammar, unless specified

          options.each_pair do |k,v|
            new_node.send :"#{k}=", v
          end

          # Nokogiri::XML::Builder.with msg.instance_variable_get(:@xml) do |xml|
          #   prompt_opts = {:voice => voice} if voice
          #   xml.prompt prompt_opts do
          #     xml.text prompt
          #   end
          #   xml.choices("content-type" => grammar_type) {
          #     if grammar_type == 'application/grammar+grxml'
          #       xml.cdata options[:choices]
          #     else
          #       xml.text options[:choices]
          #     end
          #   }
          # end

          new_node
        end

        def bargein
          self[:bargein] == "true"
        end

        def bargein=(bargein)
          self[:bargein] = bargein.to_s
        end

        def min_confidence
          self['min-confidence'].to_f
        end

        def min_confidence=(min_confidence)
          self['min-confidence'] = min_confidence
        end

        def mode
          self[:mode].to_sym
        end

        def mode=(mode)
          self[:mode] = mode
        end

        def recognizer
          self[:recognizer]
        end

        def recognizer=(recognizer)
          self[:recognizer] = recognizer
        end

        def terminator
          self[:terminator]
        end

        def terminator=(terminator)
          self[:terminator] = terminator
        end

        def response_timeout
          self[:timeout].to_i
        end

        def response_timeout=(rt)
          self[:timeout] = rt
        end

        def choices
          cn = find_first('ns:choices', :ns => self.class.registered_ns)
          {:content_type => cn['content-type'], :value => cn.text.strip} if cn
        end

        def choices=(choices)

        end
      end # Ask
    end # Ozone
  end # Protocol
end # Punchblock
