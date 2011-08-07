require 'state_machine'

module Punchblock
  class Rayo
    module Command
      extend ActiveSupport::Autoload

      autoload :Accept
      autoload :Answer
      autoload :Dial
      autoload :Hangup
      autoload :Input
      autoload :Join
      autoload :Mute
      autoload :Output
      autoload :Record
      autoload :Redirect
      autoload :Reject
      autoload :Tropo
      autoload :Unjoin
      autoload :Unmute

      InvalidActionError = Class.new StandardError

      class CommandNode < RayoNode
        attr_accessor :events

        def initialize(*args)
          super
          @events = []
        end

        def add_event(event)
          event.original_command = self
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

      class Action < CommandNode # :nodoc:
        def self.new(options = {})
          super().tap do |new_node|
            new_node.command_id = options[:command_id]
            new_node.call_id = options[:call_id]
          end
        end
      end # Action

      class Stop < Action # :nodoc:
        register :stop, :core
      end
    end # Command
  end # Rayo
end # Punchblock
