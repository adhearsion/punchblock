# encoding: utf-8

module Punchblock
  module Component
    class ComponentNode < CommandNode
      include HasGuardedHandlers

      def initialize(*args)
        super
        @complete_event_resource = FutureResource.new
        register_internal_handlers
      end

      def register_internal_handlers
        register_handler :internal, Event::Complete do |event|
          self.complete_event = event
          throw :pass
        end
      end

      def add_event(event)
        trigger_handler :internal, event
      end

      def trigger_event_handler(event)
        trigger_handler :event, event
      end

      def register_event_handler(*guards, &block)
        register_handler :event, *guards, &block
      end

      def write_action(action)
        client.execute_command action, :target_call_id => target_call_id, :component_id => component_id
        action
      end

      def response=(other)
        if other.is_a?(Ref)
          @component_id = other.id
          client.register_component self if client
        end
        super
      end

      def complete_event(timeout = nil)
        @complete_event_resource.resource timeout
      end

      def complete_event=(other)
        return if @complete_event_resource.set_yet?
        client.delete_component_registration self if client
        complete!
        @complete_event_resource.resource = other
      end

      ##
      # Create a Rayo stop message
      #
      # @return [Stop] a Rayo stop message
      #
      def stop_action
        Stop.new :component_id => component_id, :target_call_id => target_call_id
      end

      ##
      # Sends a Rayo stop message for the current component
      #
      def stop!(options = {})
        raise InvalidActionError, "Cannot stop a #{self.class.name.split("::").last} that is not executing" unless executing?
        stop_action.tap { |action| write_action action }
      end
    end
  end
end
