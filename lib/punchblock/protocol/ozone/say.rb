module Punchblock
  module Protocol
    module Ozone
      class Say < Message
        register :ozone_say, :say, 'urn:xmpp:ozone:say:1'

        # Creates the proper class from the stana's child
        # @private
        def self.import(node)
          klass = nil
          if say = node.document.find_first('//ns:say', :ns => self.registered_ns)
            say.children.each { |e| break if klass = class_from_registration(e.element_name, (e.namespace.href if e.namespace)) }
          end
          (klass || self).new(:type => node[:type]).inherit(node)
        end

        ##
        # Creates a say with a text for Ozone
        #
        # @param [String] text to speak back to a caller
        #
        # @return [Ozone::Message] an Ozone "say" message
        #
        # @example
        #   say 'Hello brown cow.'
        #
        #   returns:
        #     <say xmlns="urn:xmpp:ozone:say:1">Hello brown cow.</say>
        #
        def self.new(options = {})
          new_node = super options[:type]
          new_node.say
          new_node.say << options.delete(:text) if options.has_key?(:text)
          new_node.voice = options.delete(:voice) if options.has_key?(:voice)
          new_node.ssml = options.delete(:ssml) if options.has_key?(:ssml)
          new_node.audio = options if options.has_key?(:url)
          new_node
        end

        # Overrides the parent to ensure the say node is destroyed
        # @private
        def inherit(node)
          remove_children :say
          super
        end

        # Get or create the say node on the stanza
        #
        # @return [Blather::XMPPNode]
        def say
          unless p = find_first('ns:say', :ns => self.class.registered_ns)
            self << (p = ::Blather::XMPPNode.new('say', self.document))
            p.namespace = self.class.registered_ns
          end
          p
        end

        def voice
          say[:voice]
        end

        def voice=(voice)
          say[:voice] = voice
        end

        def audio

        end

        def audio=(audio)

        end

        def ssml=(ssml)
          if ssml.instance_of?(String)
            say << Nokogiri::XML::Node.new('', Nokogiri::XML::Document.new).parse(ssml) do |config|
              config.noblanks.strict
            end
          end
        end

        def call_id
          to.node
        end

        def command_id
          to.resource
        end

        # # Pauses a running Say
        # #
        # # @return [Ozone::Message::Say] an Ozone pause message for the current Say
        # #
        # # @example
        # #    say_obj.pause.to_xml
        # #
        # #    returns:
        # #      <pause xmlns="urn:xmpp:ozone:say:1"/>
        # def pause
        #   Say.new :pause, :parent => self
        # end
        #
        # ##
        # # Create an Ozone resume message for the current Say
        # #
        # # @return [Ozone::Message::Say] an Ozone resume message
        # #
        # # @example
        # #    say_obj.resume.to_xml
        # #
        # #    returns:
        # #      <resume xmlns="urn:xmpp:ozone:say:1"/>
        # def resume
        #   Say.new :resume, :parent => self
        # end
        #
        # ##
        # # Creates an Ozone stop message for the current Say
        # #
        # # @return [Ozone::Message] an Ozone stop message
        # #
        # # @example
        # #    stop 'say'
        # #
        # #    returns:
        # #      <stop xmlns="urn:xmpp:ozone:say:1"/>
        # def stop
        #   Say.new :stop, :parent => self
        # end
      end # Say
    end # Ozone
  end # Protocol
end # Punchblock
