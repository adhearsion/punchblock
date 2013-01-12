# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Input < Component

          include InputComponent

          private

          def register_dtmf_event_handler
            call.register_handler :es, :event_name => 'DTMF' do |event|
              safe_from_dead_actors do
                @recognizer << event[:dtmf_digit]
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
