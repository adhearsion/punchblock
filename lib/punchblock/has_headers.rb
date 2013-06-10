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
        if headers.has_key?(header[:name])
          headers[header[:name]] = [headers[header[:name]]]
          headers[header[:name]] << header[:value]
        else
          headers[header[:name]] = header[:value]
        end
      end
      super
    end

    def rayo_children(root)
      super
      headers.each do |name, value|
        Array(value).each do |v|
          root.header name: name, value: v
        end
      end
    end
  end
end
