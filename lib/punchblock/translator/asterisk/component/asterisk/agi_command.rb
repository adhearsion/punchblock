# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AGICommand < Component
            ARG_QUOTER = /["\\]/.freeze

            def execute
              ami_client.send_ami_action 'AGI', 'Channel' => @call.channel, 'Command' => agi_command, 'CommandID' => id
              send_ref
            rescue RubyAMI::Error
              set_node_response false
              terminate
            end

            def handle_ami_event(event)
              if event.name == 'AsyncAGI' && event['SubEvent'] == 'Exec'
                send_complete_event success_reason(event)
              end
            end

            private

            def agi_command
              "#{@component_node.name} #{@component_node.params_array.map { |arg| quote_arg(arg) }.join(' ')}".squish
            end

            # Arguments surrounded by quotes; quotes backslash-escaped.
            # See parse_args in asterisk/res/res_agi.c (Asterisk 1.4.21.1)
            def quote_arg(arg)
              '"' + arg.to_s.gsub(ARG_QUOTER) { |m| "\\#{m}" } + '"'
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
