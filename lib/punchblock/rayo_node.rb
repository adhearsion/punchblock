# encoding: utf-8

require 'active_support/core_ext/class/attribute'
require 'niceogiri'

module Punchblock
  class RayoNode < Niceogiri::XML::Node
    @@registrations = {}

    class_attribute :registered_ns, :registered_name

    attr_accessor :call_id, :mixer_name, :component_id, :domain, :connection, :client, :original_component

    # Register a new stanza class to a name and/or namespace
    #
    # This registers a namespace that is used when looking
    # up the class name of the object to instantiate when a new
    # stanza is received
    #
    # @param [#to_s] name the name of the node
    # @param [String, nil] ns the namespace the node belongs to
    def self.register(name, ns = nil)
      self.registered_name = name.to_s
      self.registered_ns = ns.is_a?(Symbol) ? RAYO_NAMESPACES[ns] : ns
      @@registrations[[self.registered_name, self.registered_ns]] = self
    end

    # Find the class to use given the name and namespace of a stanza
    #
    # @param [#to_s] name the name to lookup
    # @param [String, nil] xmlns the namespace the node belongs to
    # @return [Class, nil] the class appropriate for the name/ns combination
    def self.class_from_registration(name, ns = nil)
      @@registrations[[name.to_s, ns]]
    end

    # Import an XML::Node to the appropriate class
    #
    # Looks up the class the node should be then creates it based on the
    # elements of the XML::Node
    # @param [XML::Node] node the node to import
    # @return the appropriate object based on the node name and namespace
    def self.import(node, call_id = nil, component_id = nil)
      ns = (node.namespace.href if node.namespace)
      klass = class_from_registration(node.element_name, ns)
      event = if klass && klass != self
        klass.import node, call_id, component_id
      else
        new.inherit node
      end
      event.tap do |event|
        event.call_id = call_id
        event.component_id = component_id
      end
    end

    # Create a new Node object
    #
    # @param [String, nil] name the element name
    # @param [XML::Document, nil] doc the document to attach the node to. If
    # not provided one will be created
    # @return a new object with the registered name and namespace
    def self.new(name = registered_name, doc = nil)
      super name, doc, registered_ns
    end

    def inspect_attributes # :nodoc:
      [:call_id, :component_id]
    end

    def inspect
      "#<#{self.class} #{inspect_attributes.map { |c| "#{c}=#{self.__send__(c).inspect rescue nil}" }.compact * ', '}>"
    end

    def eql?(o, *fields)
      super o, *(fields + inspect_attributes)
    end

    ##
    # @return [RayoNode] the original command issued that lead to this event
    #
    def source
      @source ||= client.find_component_by_id component_id if client && component_id
      @source ||= original_component
    end

    alias :to_s :inspect
    alias :xmlns :namespace_href
  end
end
