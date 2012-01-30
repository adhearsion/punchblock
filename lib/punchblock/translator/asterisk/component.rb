module Punchblock
  module Translator
    class Asterisk
      module Component
        extend ActiveSupport::Autoload

        autoload :Asterisk
        autoload :Input
        autoload :Output

        class Component
          include Celluloid

          attr_reader :id, :call
          attr_accessor :internal

          def initialize(component_node, call = nil)
            @component_node, @call = component_node, call
            @id = UUIDTools::UUID.random_create.to_s
            setup
            pb_logger.debug "Starting up..."
          end

          def setup
          end

          def execute_command(command)
            command.response = ProtocolError.new 'command-not-acceptable', "Did not understand command for component #{id}", call_id, id
          end

          def send_complete_event(reason)
            event = Punchblock::Event::Complete.new.tap do |c|
              c.reason = reason
            end
            send_event event
            current_actor.terminate!
          end

          def send_event(event)
            event.component_id  = id
            event.call_id       = call_id
            pb_logger.debug "Sending event #{event}"
            if internal
              @component_node.add_event event
            else
              translator.connection.handle_event event
            end
          end

          def logger_id
            "#{self.class}: #{call ? "Call ID: #{call.id}, Component ID: #{id}" : id}"
          end

          def call_id
            call.id if call
          end

          private

          def translator
            call.translator
          end

          def set_node_response(value)
            pb_logger.debug "Setting response on component node to #{value}"
            @component_node.response = value
          end

          def send_ref
            set_node_response Ref.new :id => id
          end

          def with_error(name, text)
            set_node_response ProtocolError.new(name, text)
          end
        end
      end
    end
  end
end
