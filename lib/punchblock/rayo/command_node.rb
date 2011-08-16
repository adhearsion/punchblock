require 'state_machine'

module Punchblock
  class Rayo
    class CommandNode < RayoNode
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

      def write_attr(*args)
        raise StandardError, "Cannot alter attributes of a requested command" unless new?
        super
      end
    end # CommandNode
  end # Rayo
end # Punchblock
