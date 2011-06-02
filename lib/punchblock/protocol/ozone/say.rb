module Punchblock
  module Protocol
    module Ozone
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
        #     <say xmlns="urn:xmpp:ozone:say:1">Hello brown cow.</say>
        #
        def self.new(options = {})
          super('say').tap do |msg|
            msg.set_text(options.delete(:text)) if options.has_key?(:text)
            msg.instance_variable_get(:@xml).add_child msg.set_ssml(options.delete(:ssml)) if options[:ssml]
            url  = options.delete :url
            msg.set_options options.clone
            Nokogiri::XML::Builder.with(msg.instance_variable_get(:@xml)) do |xml|
              xml.audio('src' => url) if url
            end
          end
        end

        def set_options(options)
          options.each { |option, value| @xml.set_attribute option.to_s, value }
        end

        def set_ssml(ssml)
          if ssml.instance_of?(String)
            Nokogiri::XML::Node.new('', Nokogiri::XML::Document.new).parse(ssml) do |config|
              config.noblanks.strict
            end
          end
        end

        def set_text(text)
          @xml.add_child text if text
        end

        ##
        # Pauses a running Say
        #
        # @return [Ozone::Message::Say] an Ozone pause message for the current Say
        #
        # @example
        #    say_obj.pause.to_xml
        #
        #    returns:
        #      <pause xmlns="urn:xmpp:ozone:say:1"/>
        def pause
          Say.new :pause, :parent => self
        end

        ##
        # Create an Ozone resume message for the current Say
        #
        # @return [Ozone::Message::Say] an Ozone resume message
        #
        # @example
        #    say_obj.resume.to_xml
        #
        #    returns:
        #      <resume xmlns="urn:xmpp:ozone:say:1"/>
        def resume
          Say.new :resume, :parent => self
        end

        ##
        # Creates an Ozone stop message for the current Say
        #
        # @return [Ozone::Message] an Ozone stop message
        #
        # @example
        #    stop 'say'
        #
        #    returns:
        #      <stop xmlns="urn:xmpp:ozone:say:1"/>
        def stop
          Say.new :stop, :parent => self
        end
      end
    end
  end
end
