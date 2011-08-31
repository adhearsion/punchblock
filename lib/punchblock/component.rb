module Punchblock
  module Component
    extend ActiveSupport::Autoload

    autoload :Input
    autoload :Output
    autoload :Record
    autoload :Tropo

    InvalidActionError = Class.new StandardError

    class ComponentNode < CommandNode
      attr_accessor :event_queue, :complete_event, :event_callback

      def initialize(*args)
        super
        @event_queue    = Queue.new
        @complete_event = FutureResource.new
        @event_callback = nil
      end

      def add_event(event)
        event.original_component = self
        transition_state! event
        if event_callback.respond_to?(:call)
          add_event_to_queue = event_callback.call event
        end
        @event_queue << event unless add_event_to_queue
        complete_event.resource = event if event.is_a? Event::Complete
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
