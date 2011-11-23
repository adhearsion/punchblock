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
              set_node_response Ref.new :id => id

              @component_node.ssml or return
              @execution_elements = @component_node.ssml.children.map do |node|
                case node
                when RubySpeech::SSML::Audio
                  lambda { current_actor.play_audio! node.src }
                end
              end

              @pending_actions = @execution_elements.count

              @execution_elements.each &:call
            end

            def process_playback_completion
              @pending_actions -= 1
              pb_logger.debug "Received action completion. Now waiting on #{@pending_actions} actions."
              if @pending_actions < 1
                pb_logger.debug "Sending complete event"
                send_event complete_event(success_reason)
              end
            end

            def play_audio(path)
              @call.send_agi_action! 'STREAM FILE', path, '"' do |complete_event|
                current_actor.process_playback_completion
              end
            end

            private

            def set_node_response(value)
              pb_logger.debug "Setting response on component node to #{value}"
              @component_node.response = value
            end

            def success_reason
              Punchblock::Component::Output::Complete::Success.new
            end

            def complete_event(reason)
              Punchblock::Event::Complete.new.tap do |c|
                c.reason = reason
              end
            end

            def send_event(event)
              event.component_id = id
              pb_logger.debug "Sending event #{event.inspect}"
              @component_node.add_event event
            end
          end
        end
      end
    end
  end
end
