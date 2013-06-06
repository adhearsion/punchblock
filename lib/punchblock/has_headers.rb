# encoding: utf-8

module Punchblock
  module HasHeaders
    def self.included(klass)
      klass.attribute :headers, Hash, default: {}
    end

    def headers=(other)
      super(other || {})
    end

    def inherit(xml_node)
      xml_node.xpath('//ns:header', ns: self.class.registered_ns).to_a.each do |header|
        headers[header[:name]] = header[:value]
      end
      super
    end

    def rayo_children(root)
      super
      headers.each do |name, value|
        root.header name: name, value: value
      end
    end
  end
end
