# encoding: utf-8
require 'state_machine'

module Punchblock
  class CommandNode < RayoNode

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
        transition [:requested, :executing] => :complete
      end
    end

    def response(timeout = nil)
      @response.resource timeout
    end

    def response=(other)
      return if @response.set_yet?
      @response.resource = other
      execute!
    rescue FutureResource::ResourceAlreadySetException
    end
  end # CommandNode
end # Punchblock
