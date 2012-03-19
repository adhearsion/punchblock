# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AMIAction < Component
            attr_reader :action, :translator

            def initialize(component_node, translator)
              super component_node, nil
              @translator = translator
            end

            def setup
              @action = create_action
              @id = @action.action_id
            end

            def execute
              send_action
              send_ref
            end

            def handle_response(response)
              pb_logger.debug "Handling response #{response.inspect}"
              case response
              when RubyAMI::Error
                send_complete_event error_reason(response)
              when RubyAMI::Response
                send_events
                send_complete_event success_reason(response)
              end
            end

            private

            def create_action
              headers = {}
              @component_node.params_hash.each_pair do |key, value|
                headers[key.to_s.capitalize] = value
              end
              component = current_actor
              RubyAMI::Action.new @component_node.name, headers do |response|
                component.handle_response! response
              end
            end

            def send_action
              @translator.send_ami_action! @action
            end

            def error_reason(response)
              Punchblock::Event::Complete::Error.new :details => response.message
            end

            def success_reason(response)
              headers = response.headers
              headers.merge! @extra_complete_attributes if instance_variable_defined?(:@extra_complete_attributes)
              headers.delete 'ActionID'
              Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => headers.delete('Message'), :attributes => headers
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
          end
        end
      end
    end
  end
end
