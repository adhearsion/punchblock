module Punchblock
  module Translator
    class Asterisk
      class AMIAction < Component
        attr_reader :action

        def initialize(component_node, ami_client)
          @component_node, @ami_client = component_node, ami_client
          @action = create_action
          @id = @action.action_id
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
          @ami_client.send_action @action
        end

        def send_ref
          @component_node.response = Ref.new :id => @action.action_id
        end

        def handle_response(response)
          case response
          when RubyAMI::Error
            send_event error_event(response)
          when RubyAMI::Response
            send_events
            send_event complete_event(response)
          end
        end

        def error_event(response)
          Punchblock::Event::Complete.new.tap do |c|
            c.reason = Punchblock::Event::Complete::Error.new :details => response.message
          end
        end

        def complete_event(response)
          headers = response.headers
          headers.merge! @extra_complete_attributes if @extra_complete_attributes
          headers.delete 'ActionID'
          Punchblock::Event::Complete.new.tap do |c|
            c.reason = Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => headers.delete('Message'), :attributes => headers
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
          @component_node.add_event event
        end
      end
    end
  end
end
