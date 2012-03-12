# encoding: utf-8

require 'uri'
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
              @call.send_ami_action! @action
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

            def parse_agi_result(result)
              match = URI.decode(result).chomp.match(/^(\d{3}) result=(-?\d*) ?(\(?.*\)?)?$/)
              if match
                data = match[3] ? match[3].gsub(/(^\()|(\)$)/, '') : nil
                [match[1].to_i, match[2].to_i, data]
              end
            end

            private

            def create_action
              RubyAMI::Action.new 'AGI', 'Channel' => @call.channel, 'Command' => agi_command, 'CommandID' => id do |response|
                handle_response response
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

            def handle_response(response)
              pb_logger.debug "Handling response: #{response.inspect}"
              case response
              when RubyAMI::Error
                set_node_response false
              when RubyAMI::Response
                send_ref
              end
            end

            def success_reason(event)
              code, result, data = parse_agi_result event['Result']
              Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new :code => code, :result => result, :data => data
            end
          end
        end
      end
    end
  end
end
