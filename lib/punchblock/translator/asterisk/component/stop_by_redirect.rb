# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module StopByRedirect
          def execute_command(command)
            return super unless command.is_a?(Punchblock::Component::Stop)

            command.response = true
            call.redirect_back
            call.register_handler :ami, lambda { |e| e['SubEvent'] == 'Start' }, :name => 'AsyncAGI' do |event|
              send_complete_event Punchblock::Event::Complete::Stop.new
            end
          end
        end
      end
    end
  end
end
