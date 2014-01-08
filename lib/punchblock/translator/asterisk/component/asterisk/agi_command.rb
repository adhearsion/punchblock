# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class AGICommand < Component
            def setup
              @agi = Punchblock::Translator::Asterisk::AGICommand.new id, @call.channel, @component_node.name, *@component_node.params
            end

            def execute
              @agi.execute ami_client
              send_ref
            rescue RubyAMI::Error
              set_node_response false
            rescue ChannelGoneError
              set_node_response ProtocolError.new.setup(:item_not_found, "Could not find a call with ID #{call_id}", call_id)
            end

            def handle_ami_event(event)
              if event.name == 'AsyncAGI' && event['SubEvent'] == 'Exec'
                send_complete_event success_reason(event)
                if @component_node.name == 'ASYNCAGI BREAK' && @call.channel_var('PUNCHBLOCK_END_ON_ASYNCAGI_BREAK')
                  @call.handle_hangup_event
                end
              end
            end

            private

            def success_reason(event)
              result = @agi.parse_result event
              Punchblock::Component::Asterisk::AGI::Command::Complete::Success.new result
            end
          end
        end
      end
    end
  end
end
