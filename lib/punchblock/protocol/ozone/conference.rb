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

            new_node.name = name
            options.each_pair do |k,v|
              new_node.send :"#{k}=", v
            end

            # Nokogiri::XML::Builder.with(msg.instance_variable_get(:@xml)) do |xml|
            #   xml.music {
            #     xml.speak prompt if prompt
            #     xml.audio(:url => audio_url) if audio_url
            #   } if prompt || audio_url
            # end

          end
        end

        def name
          self[:name]
        end

        def name=(name)
          self[:name] = name
        end

        def beep
          self[:beep] == 'true'
        end

        def beep=(beep)
          self[:beep] = beep.to_s
        end

        def mute
          self[:mute] == 'true'
        end

        def mute=(mute)
          self[:mute] = mute.to_s
        end

        def terminator
          self[:terminator]
        end

        def terminator=(terminator)
          self[:terminator] = terminator
        end

        def tone_passthrough
          self['tone-passthrough'] == 'true'
        end

        def tone_passthrough=(tone_passthrough)
          self['tone-passthrough'] = tone_passthrough.to_s
        end

        def moderator
          self[:moderator] == 'true'
        end

        def moderator=(moderator)
          self[:moderator] = moderator.to_s
        end

        # TODO: make an announcement class
        def announcement
          an = find_first('ns:announcement', :ns => self.class.registered_ns)
          {:voice => an[:voice], :text => an.text.strip} if an
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
