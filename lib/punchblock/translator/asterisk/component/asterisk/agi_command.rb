# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AGICommand < Component
            attr_reader :action

            def setup
              @action = create_action
            end

            def execute
              send_ref
              @call.send_ami_action @action
            end

            def handle_ami_event(event)
              pb_logger.debug "Handling AMI event: #{event.inspect}"
              if event.name == 'AsyncAGI'
                if event['SubEvent'] == 'Exec'
                  pb_logger.debug "Received AsyncAGI:Exec event, sending complete event."
                  send_complete_event success_reason(event)
                end
              end
            end

            def handle_response(response)
              pb_logger.debug "Handling response: #{response.inspect}"
              case response
              when RubyAMI::Error
                set_node_response false
              when RubyAMI::Response
                send_ref
              end
            end

            private

            def create_action
              command = current_actor
              RubyAMI::Action.new 'AGI', 'Channel' => @call.channel, 'Command' => agi_command, 'CommandID' => id do |response|
                command.handle_response response
              end
            end

            def agi_command
              "#{@component_node.name} #{@component_node.params_array.map { |arg| quote_arg(arg) }.join(' ')}".squish
            end

            # Arguments surrounded by quotes; quotes backslash-escaped.
            # See parse_args in asterisk/res/res_agi.c (Asterisk 1.4.21.1)
            def quote_arg(arg)
              '"' + arg.to_s.gsub(/["\\]/) { |m| "\\#{m}" } + '"'
            end

            def success_reason(event)
              parser = RubyAMI::AGIResultParser.new event['Result']
              Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new :code => parser.code, :result => parser.result, :data => parser.data
            end
          end
        end
      end
    end
  end
end
