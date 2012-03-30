# encoding: utf-8

require 'state_machine'

module Punchblock
  class CommandNode < RayoNode
    def self.new(options = {})
      super().tap do |new_node|
        new_node.target_call_id = options[:target_call_id]
        new_node.target_mixer_name = options[:target_mixer_name]
        new_node.component_id = options[:component_id]
      end
    end

    def initialize(*args)
      super
      @response = FutureResource.new
    end

    state_machine :state, :initial => :new do
      event :request do
        transition :new => :requested
      end

      event :execute do
        transition :requested => :executing
      end

      event :complete do
        transition :executing => :complete
      end
    end

    def write_attr(*args)
      raise StandardError, "Cannot alter attributes of a requested command" unless new?
      super
    end

    def response(timeout = nil)
      @response.resource timeout
    end

    def response=(other)
      return if @response.set_yet?
      @response.resource = other
      execute!
    end

    def inspect_attributes
      super + [:state_name]
    end
  end # CommandNode
end # Punchblock
