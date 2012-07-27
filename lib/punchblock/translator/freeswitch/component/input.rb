# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Input < Component

          include InputComponent

          private

          def register_dtmf_event_handler
            component = current_actor
            call.register_handler :es, :event_name => 'DTMF' do |event|
              component.process_dtmf! event[:dtmf_digit]
            end
          end

          def unregister_dtmf_event_handler
            call.unregister_handler :es, @dtmf_handler_id if instance_variable_defined?(:@dtmf_handler_id)
          end
        end
      end
    end
  end
end
