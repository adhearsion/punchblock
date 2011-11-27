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
      node = children.first
      RubySpeech::SSML::Element.import node if node
    end

    ##
    # @param [String] ssml the SSML document to render TTS
    #
    def ssml=(ssml)
      return unless ssml
      unless ssml.is_a?(RubySpeech::SSML::Element)
        node = ssml.is_a?(Nokogiri::XML::Node) ? ssml : Nokogiri::XML(ssml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).root
        ssml = RubySpeech::SSML::Element.import node
      end
      self << ssml
    end

    def inspect_attributes # :nodoc:
      [:voice, :ssml] + super
    end
  end
end