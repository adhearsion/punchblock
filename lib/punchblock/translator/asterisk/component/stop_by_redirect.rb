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
            component_actor = current_actor
            call.register_handler :ami, lambda { |e| e['SubEvent'] == 'Start' }, :name => 'AsyncAGI' do |event|
              component_actor.send_complete_event! complete_reason
            end
            call.redirect_back!
          end
        end
      end
    end
  end
end
