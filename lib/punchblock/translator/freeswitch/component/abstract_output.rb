# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class AbstractOutput < Component
          UnrenderableDocError = Class.new OptionError

          def execute
            validate
            send_ref
            do_output
          rescue UnrenderableDocError => e
            with_error 'unrenderable document error', e.message
          rescue OptionError => e
            with_error 'option error', e.message
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

          private

          def do_output
            raise 'Not Implemented'
          end

          def validate
            raise OptionError, 'An SSML document is required.' unless @component_node.render_documents.first.value

            [:start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
              raise OptionError, "A #{opt} value is unsupported." if @component_node.send opt
            end

            case @component_node.interrupt_on
            when :voice, :dtmf, :any
              raise OptionError, "An interrupt-on value of #{@component_node.interrupt_on} is unsupported."
            end
          end

          def concatenated_render_doc
            @component_node.render_documents.inject RubySpeech::SSML.draw do |doc, argument|
              doc + argument.value
            end
          end

          def finish_reason
            Punchblock::Component::Output::Complete::Finish.new
          end
        end
      end
    end
  end
end
