module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AGICommand < Component
            attr_reader :action

            def initialize(component_node, call)
              @component_node, @call = component_node, call
              @id = UUIDTools::UUID.random_create.to_s
              @action = create_action
            end

            def execute
              @call.send_ami_action! @action
            end

            def handle_ami_event(event)
              if event.name == 'AGIExec'
                if event['SubEvent'] == 'End'
                  case event['ResultCode']
                  when '200'
                    send_event complete_event(success_reason(event))
                  end
                end
              end
            end

            private

            def create_action
              RubyAMI::Action.new 'AGI', 'Channel' => @call.channel, 'Command' => @component_node.name, 'CommandID' => id do |response|
                handle_response response
              end
            end

            def handle_response(response)
              case response
              when RubyAMI::Error
                @component_node.response = false
              when RubyAMI::Response
                @component_node.response = Ref.new :id => id
              end
            end

            def success_reason(event)
              code, result, data = event.headers.values_at 'ResultCode', 'Result', 'Data'
              Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new :code => code, :result => result, :data => data
            end

            def complete_event(reason)
              Punchblock::Event::Complete.new.tap do |c|
                c.reason = reason
              end
            end

            def send_event(event)
              @component_node.add_event event.tap { |e| e.component_id = id }
            end
          end
        end
      end
    end
  end
end
