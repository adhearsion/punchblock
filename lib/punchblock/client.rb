# encoding: utf-8

require 'celluloid'
require 'punchblock/client/component_registry'

module Punchblock
  class Client
    include HasGuardedHandlers
    include Celluloid

    execute_block_on_receiver :register_handler, :register_tmp_handler, :register_handler_with_priority, :register_event_handler

    attr_reader :connection, :component_registry

    delegate :run, :stop, :to => :connection

    # @param [Hash] options
    # @option options [Connection::XMPP] :connection The Punchblock connection to use for this session
    #
    def initialize(options = {})
      if @connection = options[:connection]
        client = current_actor
        @connection.event_handler = ->(event) { client.handle_event event }
      end
      @component_registry = ComponentRegistry.new
    end

    def handle_event(event)
      event.client = current_actor
      if event.source
        event.source.add_event event
      else
        trigger_handler :event, event
      end
    end

    def register_event_handler(*guards, &block)
      register_handler :event, *guards, &block
    end

    def register_component(component)
      component_registry << component
    end

    def find_component_by_id(component_id)
      component_registry.find_by_id component_id
    end

    def delete_component_registration(component)
      component_registry.delete component
    end

    def execute_command(command, options = {})
      client = current_actor
      command.client = current_actor
      if command.respond_to?(:register_handler)
        command.register_handler :internal do |event|
          client.trigger_handler :event, event
        end
      end
      connection.write command, options
    end
  end
end
