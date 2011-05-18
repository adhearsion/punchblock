require 'nokogiri'

module Ozone
  class Message < Nokogiri::XML::Node
    BASE_OZONE_NAMESPACE = 'urn:xmpp:ozone'
    OZONE_VERSION        = '1'
    
    ##
    # Create a new Ozone Message object.
    #
    # @param [Symbol, Required] Verb for this new message
    # @param [Nokogiri::XML::Document, Optional] Existing XML document to which this message should be added
    #
    # @return [Ozone::Message] New Ozone Message object
    def self.new(verb, doc = nil)
      obj = super verb.to_s, (doc || Nokogiri::XML::Document.new)
      obj.set_xmlns
      obj
    end

    ##
    # Set the XMLNS attribute on this message
    # @param [String] Ozone XML namespace sub-scope
    def set_xmlns(scope = nil)
      self.set_attribute 'xmlns', [BASE_OZONE_NAMESPACE, scope, OZONE_VERSION].compact.join(':')
    end
    alias :xmlns= :set_xmlns

  end

  module Messages

    ##
    # Create an answer message
    #
    # @return [Ozone::Message] a formatted Ozone answer message
    #
    # @example
    #    include Ozone::Messages
    #    msg = answer
    # 
    #    returns:
    #          <answer xmlns="urn:xmpp:ozone:1"/>
    def answer
      Message.new :answer
    end
    
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
    #    include Ozone::Messages
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
    def ask(prompt, choices, options={})
      
      # Default is the Voxeo Simple Grammar, unless specified
      grammar = options.delete(:grammar) || 'application/grammar+voxeo'
      
      msg = Message.new(:ask)
      msg.xmlns = 'ask'
      Nokogiri::XML::Builder.with(msg) do |xml|
        xml.prompt { xml.speak prompt }
        xml.choices("content-type" => grammar) {
          xml.text choices
        }
      end
      msg
    end
    
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
    #    include Ozone::Messages
    #    msg = conference({ :id => 'Please enter your postal code.', 
    #                       :beep => true,
    #                       :terminator => '#'})
    # 
    #    returns:
    #      <conference xmlns="urn:xmpp:ozone:conference:1" id="1234" beep="true" terminator="#"/>
    def conference(room_id, options={})
      prompt    = options.delete(:prompt)
      audio_url = options.delete(:audio_url)
      
      msg = Message.new :conference
      msg.xmlns = 'conference'
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
    # Creates an Ozone hangup message
    #
    # @return [Object] a Blather iq stanza object
    #
    # @example
    #    include Ozone::Messages
    #    msg = hangup
    # 
    #    returns:
    #        <hangup xmlns="urn:xmpp:ozone:1"/>
    def hangup
      Message.new :hangup
    end
    
    ##
    # Create an Ozone pause message
    #
    # @return [Ozone::Message] an Ozone pause message
    #
    # @example
    #    include Ozone::Messages
    #    msg = pause('say', '1234@ozoneserver.com/voxeo')
    # 
    #    returns:
    #      <pause xmlns="urn:xmpp:ozone:say:1"/>
    def pause
      # TODO: This method might take a verb argument if "mute" is ever namespaced
      # to a verb other than say.
      msg = Message.new :pause
      msg.xmlns = 'say'
      msg
    end
    
    ##
    # Create an Ozone resume message for a given action
    #
    # @return [Ozone::Message] an Ozone resume message
    #
    # @param [String] Action to resume
    #
    # @example
    #    include Ozone::Messages
    #    msg = resume('say')
    # 
    #    returns:
    #      <resume xmlns="urn:xmpp:ozone:say:1"/>
    def resume(verb)
      msg = Message.new :resume
      msg.xmlns = verb.to_s
      msg
    end
    
    ##
    # Create an Ozone mute message for a conference
    #
    # @return [Ozone::Message] an Ozone mute message
    #
    # @example
    #    include Ozone::Messages
    #    msg = mute
    # 
    #    returns:
    #      <mute xmlns="urn:xmpp:ozone:conference:1"/>
    def mute
      # TODO: This method might take a verb argument if "mute" is ever namespaced
      # to a verb other than conference.
      msg = Message.new :mute
      msg.xmlns = 'conference'
      msg
    end
    
    ##
    # Create an Ozone unmute conference message
    #
    # @return [Ozone::Message] an Ozone unmute message
    #
    # @example
    #    include Ozone::Messages
    #    msg = unmute
    # 
    #    returns:
    #      <unmute xmlns="urn:xmpp:ozone:conference:1"/>
    def unmute
      # TODO: This method might take a verb argument if "mute" is ever namespaced
      # to a verb other than conference.
      msg = Message.new :unmute
      msg.xmlns = 'conference'
      msg
    end
    
    ##
    # Create an Ozone conference kick message
    #
    # @return [Ozone::Message] an Ozone conference kick message
    #
    # @example
    #    include Ozone::Messages
    #    msg = kick
    # 
    #    returns:
    #      <kick xmlns="urn:xmpp:ozone:conference:1"/>
    def kick
      # TODO: This method might take a verb argument if "mute" is ever namespaced
      # to a verb other than conference.
      msg = Message.new :kick
      msg.xmlns = 'conference'
      msg
    end
    
    ##
    # Creates an Ozone stop message for a given action
    #
    # @param [String] verb to create the pause for
    #
    # @return [Ozone::Message] an Ozone stop message
    #
    # @example
    #    include Ozone::Messages
    #    msg = stop('say')
    # 
    #    returns:
    #      <stop xmlns="urn:xmpp:ozone:say:1"/>
    def stop(verb)
      msg = Message.new :stop
      msg.xmlns = verb.to_s
      msg
    end
    
    ##
    # Creates a say with an audio URL for Ozone
    #
    # @param [String] url of the audio file to playback
    #
    # @return [Ozone::Message] an Ozone say message
    # 
    # @example
    #   include Ozone::Messages
    #   say_audio :url => 'http://domain.com/rockin.wav'
    #
    #   returns:
    #     <say xmlns="urn:xmpp:ozone:say:1">
    #       <audio url="http://domain.com/rockin.wav"/>
    #     </say>
    def say_audio(url)
      msg = Message.new :say
      msg.xmlns = 'say'
      Nokogiri::XML::Builder.with(msg) do |xml| 
        xml.audio("url" => url)
      end
      msg
    end

    ##
    # Creates a say with a text for Ozone
    #
    # @param [String] text to speak back to a caller
    #
    # @return [Ozone::Message] an Ozone "say" message
    # 
    # @example
    #   include Ozone::Messages
    #   say 'Hello brown cow.' 
    #
    #   returns:
    #     <say xmlns="urn:xmpp:ozone:say:1">
    #       <speak>Hello brown cow.</speak>
    #     </say>
    def say_text(text)
      msg = Message.new :say
      msg.xmlns = 'say'
      builder = Nokogiri::XML::Builder.with(msg) do |xml| 
        xml.speak text
      end
      msg
    end

    ##
    # Creates a transfer stanza for Ozone
    #
    # @param [String] The destination for the call transfer (ie - tel:+14155551212 or sip:you@sip.tropo.com)
    #
    # @param [Hash] options for transferring a call
    # @option options [String, Optional] :terminator
    #
    # @return [Ozone::Message] an Ozone "transfer" message
    #
    # @example
    #   include Ozone::Messages
    #   transfer('sip:myapp@mydomain.com', :terminator => '#')
    #
    #   returns:
    #     <transfer xmlns="urn:xmpp:ozone:transfer:1" to="sip:myapp@mydomain.com" terminator="#"/>
    def transfer(to, options={})
      msg = Message.new :transfer
      msg.xmlns = 'transfer'
      msg.set_attribute 'to', to
      options.each do |option, value|
        msg.set_attribute option.to_s, value
      end
      msg
    end
  end
end
