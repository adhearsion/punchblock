module Punchblock
  module Protocol
    module Ozone
      class Ask < Message
        register :ozone_ask, :ask, 'urn:xmpp:ozone:ask:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if ask = node.document.find_first('//ns:ask', :ns => self.registered_ns)
            ask.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(node[:type]).inherit(node)
        end

        # Overrides the parent to ensure a ask node is created
        # @private
        def self.new(type = nil)
          new_node = super type
          new_node.ask
          new_node
        end

        # Overrides the parent to ensure the ask node is destroyed
        # @private
        def inherit(node)
          remove_children :ask
          super
        end

        # Get or create the ask node on the stanza
        #
        # @return [Blather::XMPPNode]
        def ask
          unless p = find_first('ns:ask', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('ask', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def bargein
          ask[:bargein] == "true"
        end

        def min_confidence
          ask['min-confidence'].to_f
        end

        def mode
          ask[:mode].to_sym
        end

        def recognizer
          ask[:recognizer]
        end

        def terminator
          ask[:terminator]
        end

        def response_timeout
          ask[:timeout].to_i
        end

        def choices
          cn = ask.find_first('ns:choices', :ns => self.class.registered_ns)
          {:content_type => cn['content-type'], :value => cn.text.strip}
        end

        def call_id
          to.node
        end

        def command_id
          to.resource
        end

        # ##
        # # Create an ask message
        # #
        # # @param [String] prompt to ask the caller
        # # @param [String] choices to ask the user
        # # @param [Hash] options for asking/prompting a specific call
        # # @option options [Symbol, Optional] :mode by which to accept input. Can be :speech, :dtmf or :any
        # # @option options [Integer, Optional] :timeout to wait for user input
        # # @option options [String, Optional] :recognizer to use for speech recognition
        # # @option options [String, Optional] :voice to use for speech synthesis
        # # @option options [String, Optional] :terminator by which to signal the end of input
        # # @option options [Float, Optional] :min_confidence with which to consider a response acceptable
        # # @option options [String or Nokogiri::XML, Optional] :grammar to use for speech recognition (ie - application/grammar+voxeo or application/grammar+grxml)
        # #
        # # @return [Ozone::Message] a formatted Ozone ask message
        # #
        # # @example
        # #    ask 'Please enter your postal code.',
        # #        '[5 DIGITS]',
        # #        :timeout => 30,
        # #        :recognizer => 'es-es',
        # #        :voice => 'simon'
        # #
        # #    returns:
        # #      <ask xmlns="urn:xmpp:ozone:ask:1" timeout="30" recognizer="es-es">
        # #        <prompt voice='simon'>Please enter your postal code.</prompt>
        # #        <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
        # #      </ask>
        # def self.new(prompt, options = {})
        #   super('ask').tap do |msg|
        #     voice = options.delete :voice
        #     grammar_type = options.delete(:grammar) || 'application/grammar+voxeo' # Default is the Voxeo Simple Grammar, unless specified
        #     msg.set_options options.clone
        #
        #     Nokogiri::XML::Builder.with msg.instance_variable_get(:@xml) do |xml|
        #       prompt_opts = {:voice => voice} if voice
        #       xml.prompt prompt_opts do
        #         xml.text prompt
        #       end
        #       xml.choices("content-type" => grammar_type) {
        #         if grammar_type == 'application/grammar+grxml'
        #           xml.cdata options[:choices]
        #         else
        #           xml.text options[:choices]
        #         end
        #       }
        #     end
        #   end
        # end
        #
        # def set_options(options)
        #   [:grammar, :voice, :choices].each do |val|
        #     options.delete(val) if options[val]
        #   end
        #
        #   options.each { |option, value| @xml.set_attribute option.to_s.gsub('_', '-'), value.to_s }
        # end
      end # Ask
    end # Ozone
  end # Protocol
end # Punchblock
