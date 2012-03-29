# encoding: utf-8

module Punchblock
  class Event < RayoNode
    def self.new(options = {})
      super().tap do |new_node|
        case options
        when Nokogiri::XML::Node
          new_node.inherit options
        when Hash
          options.each_pair { |k,v| new_node.send :"#{k}=", v }
        end
      end
    end
  end
end

%w{
  answered
  asterisk
  complete
  dtmf
  end
  joined
  offer
  ringing
  unjoined
  started_speaking
  stopped_speaking
}.each { |e| require "punchblock/event/#{e}"}
