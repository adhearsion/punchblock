module Punchblock
  module Protocol
    module Ozone
      class Say < Command
        register :say, :say

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
          new_node = super()
          new_node << options.delete(:text) if options.has_key?(:text)
          new_node.voice = options.delete(:voice) if options.has_key?(:voice)
          new_node.ssml = options.delete(:ssml) if options.has_key?(:ssml)
          new_node.audio = options if options.has_key?(:url)
          new_node
        end

        def voice
          self[:voice]
        end

        def voice=(voice)
          self[:voice] = voice
        end

        # TODO: Make an audio class
        def audio

        end

        def audio=(audio)

        end

        def ssml=(ssml)
          if ssml.instance_of?(String)
            self << OzoneNode.new('').parse(ssml) do |config|
              config.noblanks.strict
            end
          end
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
