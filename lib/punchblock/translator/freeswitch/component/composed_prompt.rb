# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class ComposedPrompt < Component
          include InputComponent

          def execute
            validate
            output_command.request!
            setup_dtmf_recognizer

            output_component = Output.new_link(output_command, @call)
            call.register_component output_component
            fut = output_component.future.execute

            case output_command.response
            when Ref
              send_ref
            else
              set_node_response output_command.response
            end

            fut.value unless @component_node.barge_in # Block until output is complete
            register_dtmf_event_handler

            begin
              fut.value
            rescue Celluloid::Task::TerminatedError
            end

            start_timers
          end

          def execute_command(command)
            case command
            when Punchblock::Component::Stop
              command.response = true
              application 'break'
              send_complete_event Punchblock::Event::Complete::Stop.new
            else
              super
            end
          end

          def process_dtmf(digit)
            application 'break' if @component_node.barge_in
            super
          end

          def output_command
            @output_command ||= @component_node.output
          end

          private

          def input_node
            @input_node ||= @component_node.input
          end

          def register_dtmf_event_handler
            component = current_actor
            @dtmf_handler_id = call.register_handler :es, :event_name => 'DTMF' do |event|
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
