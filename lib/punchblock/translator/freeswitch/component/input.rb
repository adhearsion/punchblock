# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Input < Component

          include InputComponent

          def execute
            super
            @dtmf_handler_id = register_dtmf_event_handler
          end

          private

          def register_dtmf_event_handler
            component = current_actor
            call.register_handler :es, :event_name => 'DTMF' do |event|
              safe_from_dead_actors do
                component.process_dtmf event[:dtmf_digit]
              end
            end
          end

          def unregister_dtmf_event_handler
            call.unregister_handler :es, @dtmf_handler_id if instance_variable_defined?(:@dtmf_handler_id)
          rescue Celluloid::DeadActorError
          end
        end
      end
    end
  end
end
