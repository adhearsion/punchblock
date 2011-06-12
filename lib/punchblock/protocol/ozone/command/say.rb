module Punchblock
  module Protocol
    class Ozone
      module Command
        class Say < OzoneNode
          register :say, :say

          ##
          # Creates a say with a text for Ozone
          #
          # @param [Hash] options
          # @option options [String] :text to speak back to a caller
          #
          # @return [Ozone::Message] an Ozone "say" message
          #
          # @example
          #   say :text => 'Hello brown cow.'
          #
          #   returns:
          #     <say xmlns="urn:xmpp:ozone:say:1">Hello brown cow.</say>
          #
          def self.new(options = {})
            super().tap do |new_node|
              case options
              when Hash
                new_node << options.delete(:text) if options[:text]
                new_node.voice = options.delete(:voice) if options[:voice]
                new_node.ssml = options.delete(:ssml) if options[:ssml]
                new_node.audio = options if options[:url]
              when Nokogiri::XML::Element
                new_node.inherit options
              end
            end
          end

          def voice
            read_attr :voice
          end

          def voice=(voice)
            write_attr :voice, voice
          end

          def audio
            node = find_first('//ns:audio', :ns => self.registered_ns)
            Audio.new node if node
          end

          def audio=(audio)
            remove_children :audio
            self << Audio.new(audio) if audio.present?
          end

          def ssml
            content.strip
          end

          def ssml=(ssml)
            if ssml.instance_of?(String)
              self << OzoneNode.new('').parse(ssml) do |config|
                config.noblanks.strict
              end
            end
          end

          def attributes
            [:voice, :audio, :ssml] + super
          end

          class Complete
            class Success < Ozone::Event::Complete::Reason
              register :success, :say_complete
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
      end
    end # Ozone
  end # Protocol
end # Punchblock
