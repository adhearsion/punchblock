module Punchblock
  module Translator
    class Asterisk
      module Component
        extend ActiveSupport::Autoload

        autoload :Asterisk

        class Component
          include Celluloid

          attr_reader :id

          def initialize(component_node, call = nil)
            @component_node, @call = component_node, call
            @id = UUIDTools::UUID.random_create.to_s
            setup
            pb_logger.debug "Starting up..."
          end

          def setup
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

          def complete_event(reason)
            Punchblock::Event::Complete.new.tap do |c|
              c.reason = reason
            end
          end

          def send_event(event)
            event.component_id = id
            pb_logger.debug "Sending event #{event}"
            @component_node.add_event event
          end
        end
      end
    end
  end
end
