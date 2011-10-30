module Punchblock
  module Component
    extend ActiveSupport::Autoload

    autoload :Input
    autoload :Output
    autoload :Record
    autoload :Tropo

    InvalidActionError = Class.new StandardError

    class ComponentNode < CommandNode
      include HasGuardedHandlers

      attr_accessor :complete_event

      def initialize(*args)
        super
        @complete_event = FutureResource.new
        register_initial_handlers
      end

      def register_initial_handlers
        register_event_handler Event::Complete do |event|
          complete!
          complete_event.resource = event
          throw :pass
        end
      end

      def add_event(event)
        event.original_component = self
        trigger_handler :event, event
      end

      def register_event_handler(*guards, &block)
        register_handler :event, *guards, &block
      end

      def write_action(action)
        client.execute_command action, :call_id => call_id, :component_id => component_id
        action
      end

      def response=(other)
        if other.is_a?(Ref)
          @component_id = other.id
          client.register_component self
        end
        super
      end

      ##
      # Create an Rayo stop message
      #
      # @return [Stop] an Rayo stop message
      #
      def stop_action
        Stop.new :component_id => component_id, :call_id => call_id
      end

      ##
      # Sends an Rayo stop message for the current component
      #
      def stop!(options = {})
        raise InvalidActionError, "Cannot stop a #{self.class.name.split("::").last} that is not executing" unless executing?
        stop_action.tap { |action| write_action action }
      end
    end

    class Stop < CommandNode # :nodoc:
      register :stop, :core
    end
  end # Component
end # Punchblock
