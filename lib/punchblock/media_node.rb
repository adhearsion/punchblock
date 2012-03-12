# encoding: utf-8

module Punchblock
  class MediaNode < RayoNode
    include MediaContainer

    def self.new(options = {})
      super().tap do |new_node|
        case options
        when Hash
          new_node << options.delete(:text) if options[:text]
          options.each_pair { |k,v| new_node.send :"#{k}=", v }
        when Nokogiri::XML::Element
          new_node.inherit options
        end
      end
    end
  end
end
