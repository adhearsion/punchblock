# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Input < Component

          include InputComponent

          def execute
            @call.send_progress
            super
          end

          private

          def register_dtmf_event_handler
            component = current_actor
            call.register_handler :ami, :name => 'DTMF', [:[], 'End'] => 'Yes' do |event|
              component.process_dtmf! event['Digit']
            end
          end

          def unregister_dtmf_event_handler
            call.unregister_handler :ami, @dtmf_handler_id if instance_variable_defined?(:@dtmf_handler_id) if call.alive?
          end
        end
      end
    end
  end
end
