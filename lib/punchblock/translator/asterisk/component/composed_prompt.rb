# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        class ComposedPrompt < Component
          include InputComponent
          include StopByRedirect

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

            if @component_node.barge_in
              register_dtmf_event_handler
            else
              fut.value # Block until output is complete before allowing input
              register_dtmf_event_handler
            end

            fut.value # Block until output is complete before starting timers
            start_timers # TODO: only do this if we havn't had input yet
          end

          def process_dtmf(digit)
            call.async.redirect_back if @component_node.barge_in
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
            @dtmf_handler_id = call.register_handler :ami, :name => 'DTMF', [:[], 'End'] => 'Yes' do |event|
              component.process_dtmf event['Digit']
            end
          end

          def unregister_dtmf_event_handler
            call.async.unregister_handler :ami, @dtmf_handler_id if instance_variable_defined?(:@dtmf_handler_id)
          end
        end
      end
    end
  end
end
