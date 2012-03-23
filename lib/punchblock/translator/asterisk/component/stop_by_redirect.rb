# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module StopByRedirect
          def execute_command(command)
            case command
            when Punchblock::Component::Stop
              command.response = true
              call.redirect_back
              call.register_handler :ami, :name => 'AsyncAGI' do |event|
                if event['SubEvent'] == "Start"
                  send_complete_event Punchblock::Event::Complete::Stop.new
                end
              end
            else
              super
            end
          end
        end
      end
    end
  end
end
