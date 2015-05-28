# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module StopByRedirect
          def execute_command(command)
            return super unless command.is_a?(Punchblock::Component::Stop)
            if @complete
              command.response = ProtocolError.new.setup 'component-already-stopped', "Component #{id} is already stopped", call_id, id
            else
              stop_by_redirect Punchblock::Event::Complete::Stop.new
              command.response = true
            end
          end

          def stop_by_redirect(complete_reason)
            call.register_handler :ami, [{name: 'AsyncAGI', [:[], 'SubEvent'] => 'Start'}, {name: 'AsyncAGIExec'}] do |event|
              send_complete_event complete_reason
            end
            call.redirect_back
          end
        end
      end
    end
  end
end
