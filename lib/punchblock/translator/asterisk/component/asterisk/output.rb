module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class Output < Component

            def initialize(component_node, call)
              @component_node, @call = component_node, call
              @id = UUIDTools::UUID.random_create.to_s
              pb_logger.debug "Starting up..."
            end

            def execute
              audio_filename = ''
              @call.send_agi_action! 'STREAM FILE', @component_node.ssml.children.first.src, '"'
            end

            # private

            # def set_node_response(value)
            #   pb_logger.debug "Setting response on component node to #{value}"
            #   @component_node.response = value
            # end

            # def success_reason(event)
            #   code, result, data = parse_agi_result event['Result']
            #   Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new :code => code, :result => result, :data => data
            # end

            # def complete_event(reason)
            #   Punchblock::Event::Complete.new.tap do |c|
            #     c.reason = reason
            #   end
            # end

            # def send_event(event)
            #   event.component_id = id
            #   pb_logger.debug "Sending event #{event.inspect}"
            #   @component_node.add_event event
            # end
          end
        end
      end
    end
  end
end
