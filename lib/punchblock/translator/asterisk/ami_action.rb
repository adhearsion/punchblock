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
            send_events
            send_complete_event
          end
        end

        def send_action
          @ami_client.send_action @action
        end

        def send_ref
          @component_node.response = Ref.new :id => @action.action_id
        end

        def complete_event
          headers = @action.response.headers
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

        def send_complete_event
          send_event complete_event
        end
      end
    end
  end
end
