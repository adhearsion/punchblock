module Punchblock
  module Protocol
    class Ozone
      module Command
        extend ActiveSupport::Autoload

        autoload :Accept
        autoload :Answer
        autoload :Ask
        autoload :Conference
        autoload :Dial
        autoload :Hangup
        autoload :Redirect
        autoload :Reject
        autoload :Say
        autoload :Transfer

        class CommandNode < OzoneNode
          attr_accessor :events

          def initialize(*args)
            super
            @events = []
          end

          def add_event(event)
            event.original_command = self
            @events << event
          end
        end # CommandNode
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
