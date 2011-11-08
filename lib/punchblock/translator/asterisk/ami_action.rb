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
          Punchblock::Component::Asterisk::AMI::Action::Complete::Success.new :message => @action.response['Message']
        end

        def send_complete_event
          @component_node.complete_event.resource = complete_event
        end
      end
    end
  end
end
