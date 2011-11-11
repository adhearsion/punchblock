module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AMIAction < Component
            attr_reader :action

            def initialize(component_node, translator)
              @component_node, @translator = component_node, translator
              @action = create_action
              @id = @action.action_id
              pb_logger.debug "Starting up..."
            end

            def execute
              send_action
              send_ref
            end

            private

            def create_action
              headers = {}
              @component_node.params_hash.each_pair do |key, value|
                headers[key.to_s.capitalize] = value
              end
              RubyAMI::Action.new @component_node.name, headers do |response|
                handle_response response
              end
            end

            def send_action
              @translator.send_ami_action! @action
            end

            def send_ref
              @component_node.response = Ref.new :id => @action.action_id
            end

            def handle_response(response)
              pb_logger.debug "Handling response #{response.inspect}"
              case response
              when RubyAMI::Error
                send_event complete_event(error_reason(response))
              when RubyAMI::Response
                send_events
                send_event complete_event(success_reason(response))
              end
            end

            def error_reason(response)
              Punchblock::Event::Complete::Error.new :details => response.message
            end

            def success_reason(response)
              headers = response.headers
              headers.merge! @extra_complete_attributes if @extra_complete_attributes
              headers.delete 'ActionID'
              Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => headers.delete('Message'), :attributes => headers
            end

            def complete_event(reason)
              Punchblock::Event::Complete.new.tap do |c|
                c.reason = reason
              end
            end

            def send_events
              return unless @action.has_causal_events?
              @action.events.each do |e|
                if e.name.downcase == @action.causal_event_terminator_name
                  @extra_complete_attributes = e.headers
                else
                  send_event pb_event_from_ami_event(e)
                end
              end
            end

            def pb_event_from_ami_event(ami_event)
              headers = ami_event.headers
              headers.delete 'ActionID'
              Event::Asterisk::AMI::Event.new :name => ami_event.name, :attributes => headers
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
end
