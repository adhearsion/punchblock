require 'punchblock/protocol/ozone/say'

module Punchblock
  module Protocol
    module Ozone
      class Conference < Command
        register :conference, :conference

        ##
        # Creates an Ozone conference message
        #
        # @param [String] room id to with which to create or join the conference
        # @param [Hash] options for conferencing a specific call
        # @option options [String, Optional] :audio_url URL to play to the caller
        # @option options [String, Optional] :prompt Text to speak to the caller
        #
        # @return [Object] a Blather iq stanza object
        #
        # @example
        #    conference :id => 'Please enter your postal code.',
        #               :beep => true,
        #               :terminator => '#'
        #
        #    returns:
        #      <conference xmlns="urn:xmpp:ozone:conference:1" id="1234" beep="true" terminator="#"/>
        def self.new(name = nil, options = {})
          super().tap do |new_node|
            prompt    = options.delete :prompt
            audio_url = options.delete :audio_url

            new_node.announcement = {:text => prompt, :url => audio_url}

            new_node.name = name
            options.each_pair do |k,v|
              new_node.send :"#{k}=", v
            end
          end
        end

        def name
          read_attr :name
        end

        def name=(name)
          write_attr :name, name
        end

        def beep
          read_attr(:beep) == 'true'
        end

        def beep=(beep)
          write_attr :beep, beep.to_s
        end

        def mute
          read_attr(:mute) == 'true'
        end

        def mute=(mute)
          write_attr :mute, mute.to_s
        end

        def terminator
          read_attr :terminator
        end

        def terminator=(terminator)
          write_attr :terminator, terminator
        end

        def tone_passthrough
          read_attr('tone-passthrough') == 'true'
        end

        def tone_passthrough=(tone_passthrough)
          write_attr 'tone-passthrough', tone_passthrough.to_s
        end

        def moderator
          read_attr(:moderator) == 'true'
        end

        def moderator=(moderator)
          write_attr :moderator, moderator.to_s
        end

        def announcement
          Announcement.new find_first('//ns:announcement', :ns => self.registered_ns)
        end

        def announcement=(ann)
          self << Announcement.new(ann)
        end

        class Announcement < Say
          register :announcement, :conference
        end

        class OnHold < Event
          register :'on-hold', :conference
        end

        class OffHold < Event
          register :'off-hold', :conference
        end

        class Complete
          class Kick < Ozone::Complete::Reason
            register :kick, :conference_complete

            alias :details :text
          end

          class Terminator < Ozone::Complete::Reason
            register :terminator, :conference_complete
          end
        end

        # ##
        # # Create an Ozone mute message for the current conference
        # #
        # # @return [Ozone::Message::Conference] an Ozone mute message
        # #
        # # @example
        # #    conf_obj.mute.to_xml
        # #
        # #    returns:
        # #      <mute xmlns="urn:xmpp:ozone:conference:1"/>
        # def mute
        #   Conference.new :mute, :parent => self
        # end
        #
        # ##
        # # Create an Ozone unmute message for the current conference
        # #
        # # @return [Ozone::Message::Conference] an Ozone unmute message
        # #
        # # @example
        # #    conf_obj.unmute.to_xml
        # #
        # #    returns:
        # #      <unmute xmlns="urn:xmpp:ozone:conference:1"/>
        # def unmute
        #   Conference.new :unmute, :parent => self
        # end
        #
        # ##
        # # Create an Ozone conference kick message
        # #
        # # @return [Ozone::Message::Conference] an Ozone conference kick message
        # #
        # # @example
        # #    conf_obj.kick.to_xml
        # #
        # #    returns:
        # #      <kick xmlns="urn:xmpp:ozone:conference:1"/>
        # def kick
        #   Conference.new :kick, :parent => self
        # end

      end # Conference
    end # Ozone
  end # Protocol
end # Punchblock
