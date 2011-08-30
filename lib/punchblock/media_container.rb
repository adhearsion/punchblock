module Punchblock
  module MediaContainer
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
    # @return [String] the SSML document to render TTS
    #
    def ssml
      children.to_xml
    end

    ##
    # @param [String] ssml the SSML document to render TTS
    #
    def ssml=(ssml)
      if ssml.instance_of?(String)
        self << RayoNode.new('').parse(ssml) do |config|
          config.noblanks.strict
        end
      end
    end

    def inspect_attributes # :nodoc:
      [:voice, :ssml] + super
    end
  end
end