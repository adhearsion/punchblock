module Punchblock
  module Protocol
    module Ozone
      class Conference < Message

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
        def self.new(name, options = {})
          super('conference').tap do |msg|
            prompt    = options.delete :prompt
            audio_url = options.delete :audio_url

            options[:name] = name
            msg.set_options options

            Nokogiri::XML::Builder.with(msg.instance_variable_get(:@xml)) do |xml|
              xml.music {
                xml.speak prompt if prompt
                xml.audio(:url => audio_url) if audio_url
              } if prompt || audio_url
            end
          end
        end

        def set_options(options)
          options.each do |option, value|
            @xml.set_attribute option.to_s.gsub('_', '-'), value.to_s
          end
        end

        ##
        # Create an Ozone mute message for the current conference
        #
        # @return [Ozone::Message::Conference] an Ozone mute message
        #
        # @example
        #    conf_obj.mute.to_xml
        #
        #    returns:
        #      <mute xmlns="urn:xmpp:ozone:conference:1"/>
        def mute
          Conference.new :mute, :parent => self
        end

        ##
        # Create an Ozone unmute message for the current conference
        #
        # @return [Ozone::Message::Conference] an Ozone unmute message
        #
        # @example
        #    conf_obj.unmute.to_xml
        #
        #    returns:
        #      <unmute xmlns="urn:xmpp:ozone:conference:1"/>
        def unmute
          Conference.new :unmute, :parent => self
        end

        ##
        # Create an Ozone conference kick message
        #
        # @return [Ozone::Message::Conference] an Ozone conference kick message
        #
        # @example
        #    conf_obj.kick.to_xml
        #
        #    returns:
        #      <kick xmlns="urn:xmpp:ozone:conference:1"/>
        def kick
          Conference.new :kick, :parent => self
        end

      end # Conference
    end # Ozone
  end # Protocol
end # Punchblock
