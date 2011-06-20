module Punchblock
  module Protocol
    class Ozone
      module Command
        class Say < CommandNode
          register :say, :say

          ##
          # Creates an Ozone Say command
          #
          # @param [Hash] options
          # @option options [String] :text to speak back
          # @option options [String] :voice with which to render TTS
          # @option options [String] :url of a recording to play
          # @option options [String] :ssml document to render TTS
          #
          # @return [Ozone::Command::Say] an Ozone "say" command
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

          ##
          # @return [String] the TTS voice to use
          #
          def voice
            read_attr :voice
          end

          ##
          # @param [String] voice to use when rendering TTS
          #
          def voice=(voice)
            write_attr :voice, voice
          end

          ##
          # @return [Audio] the audio to play
          #
          def audio
            node = find_first('//ns:audio', :ns => self.registered_ns)
            Audio.new node if node
          end

          ##
          # @param [Hash] audio
          # @option audio [String] :url of a recording to play
          #
          def audio=(audio)
            remove_children :audio
            self << Audio.new(audio) if audio.present?
          end

          ##
          # @return [String] the SSML document to render TTS
          #
          def ssml
            content.strip
          end

          ##
          # @param [String] ssml the SSML document to render TTS
          #
          def ssml=(ssml)
            if ssml.instance_of?(String)
              self << OzoneNode.new('').parse(ssml) do |config|
                config.noblanks.strict
              end
            end
          end

          def attributes # :nodoc:
            [:voice, :audio, :ssml] + super
          end

          state_machine :state do
            event :paused do
              transition :executing => :paused
            end

            event :resumed do
              transition :paused => :executing
            end
          end

          # Pauses a running Say
          #
          # @return [Ozone::Command::Say::Pause] an Ozone pause message for the current Say
          #
          # @example
          #    say_obj.pause!.to_xml
          #
          #    returns:
          #      <pause xmlns="urn:xmpp:ozone:say:1"/>
          def pause!
            raise InvalidActionError, "Cannot pause a Say that is not executing." unless executing?
            Pause.new :command_id => command_id
          end

          ##
          # Create an Ozone resume message for the current Say
          #
          # @return [Ozone::Command::Say::Resume] an Ozone resume message
          #
          # @example
          #    say_obj.resume!.to_xml
          #
          #    returns:
          #      <resume xmlns="urn:xmpp:ozone:say:1"/>
          def resume!
            raise InvalidActionError, "Cannot resume a Say that is not paused." unless paused?
            Resume.new :command_id => command_id
          end

          ##
          # Creates an Ozone stop message for the current Say
          #
          # @return [Ozone::Command::Say::Stop] an Ozone stop message
          #
          # @example
          #    say_obj.stop!.to_xml
          #
          #    returns:
          #      <stop xmlns="urn:xmpp:ozone:say:1"/>
          def stop!
            raise InvalidActionError, "Cannot stop a Say that is not executing." unless executing?
            Stop.new :command_id => command_id
          end

          class Pause < Action # :nodoc:
            register :pause, :say
          end

          class Resume < Action # :nodoc:
            register :resume, :say
          end

          class Stop < Action # :nodoc:
            register :stop, :say
          end

          class Complete
            class Success < Ozone::Event::Complete::Reason
              register :success, :say_complete
            end
          end
        end # Say
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
