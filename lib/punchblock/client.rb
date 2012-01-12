module Punchblock
  class Client
    extend ActiveSupport::Autoload

    autoload :ComponentRegistry

    include HasGuardedHandlers

    attr_reader :connection, :event_queue, :component_registry

    delegate :run, :stop, :to => :connection

    # @param [Hash] options
    # @option options [Connection::XMPP] :connection The Punchblock connection to use for this session
    #
    def initialize(options = {})
      @event_queue = Queue.new
      @connection = options[:connection]
      @connection.event_handler = lambda { |event| self.handle_event event } if @connection
      register_initial_handlers
      @component_registry = ComponentRegistry.new
      @write_timeout = options[:write_timeout] || 3
    end

    def handle_event(event)
      event.client = self
      pb_logger.warn "Handling event #{event} with source #{event.source}."
      if event.source
        event.source.add_event event
      else
        trigger_handler :event, event
      end
    end

    def register_event_handler(*guards, &block)
      register_handler :event, *guards, &block
    end

    def register_initial_handlers
      register_handler_with_priority :event, -10 do |event|
        event_queue.push event
      end
    end

    def register_component(component)
      component_registry << component
    end

    def find_component_by_id(component_id)
      component_registry.find_by_id component_id
    end

    def execute_command(command, options = {})
      pb_logger.debug "Executing command: #{command.inspect} with options #{options.inspect}"
      async = options.has_key?(:async) ? options.delete(:async) : true
      command.client = self
      if command.respond_to?(:register_handler)
        command.register_handler :internal do |event|
          trigger_handler :event, event
        end
      end
      connection.write command, options
      command.response(@write_timeout).tap { |result| raise result if result.is_a? Exception } unless async
    end
  end
end
