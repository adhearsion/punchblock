require 'state_machine'

module Punchblock
  class Rayo
    class CommandNode < RayoNode
      attr_accessor :events

      def initialize(*args)
        super
        @events = []
      end

      def add_event(event)
        event.original_component = self
        @events << event
        transition_state! event
      end

      def transition_state!(event)
        complete! if event.is_a? Rayo::Event::Complete
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
    end # CommandNode
  end # Rayo
end # Punchblock
