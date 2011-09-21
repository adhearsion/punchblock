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
          complete_event.resource = event
          throw :pass
        end
      end

      def add_event(event)
        event.original_component = self
        transition_state! event
        trigger_handler :event, event
      end

      def register_event_handler(*guards, &block)
        register_handler :event, *guards, &block
      end

      def transition_state!(event)
        complete! if event.is_a? Event::Complete
      end

      def write_action(action)
        connection.write call_id, action, component_id
      end

      def response=(other)
        super
        if other.is_a?(Blather::Stanza::Iq)
          ref = other.rayo_node
          if ref.is_a?(Ref)
            @component_id = ref.id
            @connection.record_command_id_for_iq_id @component_id, other.id
          end
        end
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
