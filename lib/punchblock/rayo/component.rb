module Punchblock
  class Rayo
    module Component
      extend ActiveSupport::Autoload

      autoload :Input
      autoload :Output
      autoload :Record
      autoload :Tropo

      InvalidActionError = Class.new StandardError

      class ComponentNode < CommandNode
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
      end

      class Action < CommandNode # :nodoc:
        def self.new(options = {})
          super().tap do |new_node|
            new_node.component_id = options[:component_id]
            new_node.call_id = options[:call_id]
          end
        end
      end # Action

      class Stop < Action # :nodoc:
        register :stop, :core
      end
    end # Component
  end # Rayo
end # Punchblock
