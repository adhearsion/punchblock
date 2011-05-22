require 'nokogiri'

module Punchblock
  module Protocol

    ##
    # This exception may be raised if a protocol error is detected.
    class ProtocolError < StandardError; end

    module Ozone
      class Message < Nokogiri::XML::Node
        BASE_OZONE_NAMESPACE = 'urn:xmpp:ozone'
        OZONE_VERSION        = '1'
        BASE_NAMESPACE_MESSAGES = %w[answer hangup]

        # Parent object that created this object, if applicable
        attr_accessor :parent, :call_id, :cmd_id

        ##
        # Create a new Ozone Message object.
        #
        # @param [Symbol, Required] Component for this new message
        # @param [Nokogiri::XML::Document, Optional] Existing XML document to which this message should be added
        #
        # @return [Ozone::Message] New Ozone Message object
        def self.new(klass, command = nil, parent = nil)
          # Ugly hack: we have to pass in the class name because
          # self.class returns "Class" right now
          name = klass.to_s.downcase
          element = command.nil? ? name : command
          obj = super element, Nokogiri::XML::Document.new
          scope = BASE_NAMESPACE_MESSAGES.include?(name) ? nil : name
          xmlns = [BASE_OZONE_NAMESPACE, scope, OZONE_VERSION].compact.join(':')
          obj.set_attribute 'xmlns', xmlns
          obj.parent = parent
          obj
        end

        def self.parse(xml)
          case xml['type']
          when 'set'
            msg = xml.children.first
            case msg.name
            when 'offer'
              # Collect headers into an array
              headers = msg.children.inject({}) do |headers, header|
                headers[header['name']] = header['value']
                headers
              end
              call = Punchblock::Call.new(xml['from'], msg['to'], headers)
              # TODO: Acknowledge the offer?
              return call
            when 'complete'

            when 'info'
            when 'end'
              unless msg.first.name == 'error'
                return End.new msg.first.name
              end
            end
          when 'result'
            Result.new xml
            if xml.children.count > 0
              case xml.children.first.name
              when 'ref'
              end
            end
          when 'error'
          else
            raise ProtocolError
          end
        end

        ##
        # An Ozone answer message
        #
        # @example
        #    Answer.new.to_xml
        #
        #    returns:
        #        <hangup xmlns="urn:xmpp:ozone:1"/>
        class Answer < Message
          def self.new
            super 'answer'
          end
        end

        ##
        # An Ozone hangup message
        #
        # @example
        #    Hangup.new.to_xml
        #
        #    returns:
        #        <hangup xmlns="urn:xmpp:ozone:1"/>
        class Hangup < Message
          def self.new
            super 'hangup'
          end
        end

        class Ask < Message
          ##
          # Create an ask message
          #
          # @param [String] prompt to ask the caller
          # @param [String] choices to ask the user
          # @param [Hash] options for asking/prompting a specific call
          # @option options [Integer, Optional] :timeout to wait for user input
          # @option options [String, Optional] :recognizer to use for speech recognition
          # @option options [String, Optional] :voice to use for speech synthesis
          # @option options [String, Optional] :grammar to use for speech recognition (ie - application/grammar+voxeo or application/grammar+grxml)
          #
          # @return [Ozone::Message] a formatted Ozone ask message
          #
          # @example
          #    msg = ask('Please enter your postal code.',
          #              '[5 DIGITS]',
          #              :timeout => 30,
          #              :recognizer => 'es-es')
          #
          #    returns:
          #      <ask xmlns="urn:xmpp:ozone:ask:1" timeout="30" recognizer="es-es">
          #        <prompt>
          #          <speak>Please enter your postal code.</speak>
          #        </prompt>
          #        <choices content-type="application/grammar+voxeo">[5 DIGITS]</choices>
          #      </ask>
          def self.new(prompt, choices, options={})

            # Default is the Voxeo Simple Grammar, unless specified
            grammar = options.delete(:grammar) || 'application/grammar+voxeo'

            msg = super 'ask'
            Nokogiri::XML::Builder.with(msg) do |xml|
              xml.prompt { xml.speak prompt }
              xml.choices("content-type" => grammar) {
                xml.text choices
              }
            end
            msg
          end
        end

        class Say < Message
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
          #     <say xmlns="urn:xmpp:ozone:say:1">
          #       <speak>Hello brown cow.</speak>
          #     </say>
          def self.new(options={})
            msg = super 'say'
            text = options.delete(:text)
            url  = options.delete(:url)
            builder = Nokogiri::XML::Builder.with(msg) do |xml|
              xml.speak text if text
              xml.audio("url" => url) if url
            end
            msg
          end

          ##
          # Pauses a running Say
          #
          # @return [Ozone::Message::Say] an Ozone pause message for the current Say
          #
          # @example
          #    msg = say_obj.pause.to_xml
          #
          #    returns:
          #      <pause xmlns="urn:xmpp:ozone:say:1"/>
          def pause
            Say.new :pause, self
          end

          ##
          # Create an Ozone resume message for the current Say
          #
          # @return [Ozone::Message::Say] an Ozone resume message
          #
          # @example
          #    msg = say_obj.resume.to_xml
          #
          #    returns:
          #      <resume xmlns="urn:xmpp:ozone:say:1"/>
          def resume
            Say.new :resume, self
          end

          ##
          # Creates an Ozone stop message for the current Say
          #
          # @return [Ozone::Message] an Ozone stop message
          #
          # @example
          #    msg = stop('say')
          #
          #    returns:
          #      <stop xmlns="urn:xmpp:ozone:say:1"/>
          def stop
            Say.new :stop, self
          end
        end

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
          #    msg = conference({ :id => 'Please enter your postal code.',
          #                       :beep => true,
          #                       :terminator => '#'})
          #
          #    returns:
          #      <conference xmlns="urn:xmpp:ozone:conference:1" id="1234" beep="true" terminator="#"/>
          def self.new(room_id, options={})
            msg = super 'conference'

            prompt    = options.delete(:prompt)
            audio_url = options.delete(:audio_url)

            msg.set_attribute 'id', room_id
            msg.set_attribute 'beep', 'true' if options.delete(:beep)
            msg.set_attribute 'terminator', options.delete(:terminator) if options.has_key?(:terminator)
            Nokogiri::XML::Builder.with(msg) do |xml|
              xml.music {
                xml.speak prompt if prompt
                xml.audio(:url => audio_url) if audio_url
              } if prompt || audio_url
            end
            msg
          end

          ##
          # Create an Ozone mute message for the current conference
          #
          # @return [Ozone::Message::Conference] an Ozone mute message
          #
          # @example
          #    msg = conf_obj.mute.to_xml
          #
          #    returns:
          #      <mute xmlns="urn:xmpp:ozone:conference:1"/>
          def mute
            Conference.new :mute, self
          end

          ##
          # Create an Ozone unmute message for the current conference
          #
          # @return [Ozone::Message::Conference] an Ozone unmute message
          #
          # @example
          #    msg = conf_obj.unmute.to_xml
          #
          #    returns:
          #      <unmute xmlns="urn:xmpp:ozone:conference:1"/>
          def unmute
            Conference.new :unmute, self
          end

          ##
          # Create an Ozone conference kick message
          #
          # @return [Ozone::Message::Conference] an Ozone conference kick message
          #
          # @example
          #    msg = conf_obj.kick.to_xml
          #
          #    returns:
          #      <kick xmlns="urn:xmpp:ozone:conference:1"/>
          def kick
            Conference.new :kick, self
          end

        end

        class Transfer < Message
          ##
          # Creates a transfer message for Ozone
          #
          # @param [String] The destination for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com)
          #
          # @param [Hash] options for transferring a call
          # @option options [String, Optional] :terminator
          #
          # @return [Ozone::Message::Transfer] an Ozone "transfer" message
          #
          # @example
          #   Transfer.new('sip:myapp@mydomain.com', :terminator => '#').to_xml
          #
          #   returns:
          #     <transfer xmlns="urn:xmpp:ozone:transfer:1" to="sip:myapp@mydomain.com" terminator="#"/>
          def self.new(to, options={})
            msg = super 'transfer'
            msg.set_attribute 'to', to
            options.each do |option, value|
              msg.set_attribute option.to_s, value
            end
            msg
          end
        end

        class Offer < Message
          ##
          # Creates an Offer message.
          # This message may not be sent by a client; this object is used
          # to represent an offer received from the Ozone server.
          def self.parse(xml)
            msg = self.new 'offer'
            @headers = xml.to_h
          end
        end

        class End < Message
          ##
          # Creates an End message.  This signfies the end of a call.
          # This message may not be sent by a client; this object is used
          # to represent an offer received from the Ozone server.
          def self.parse(xml)
            msg = self.new 'offer'
            @headers = xml.to_h
          end
        end

        class Info < Message
          def self.parse(xml)
            msg = self.new 'info'
            @headers = xml.to_h
          end
        end

        class Result < Message
          def self.parse(xml)
            msg = self.new 'info'
            @headers = xml.to_h
          end
        end
      end
    end
  end
end