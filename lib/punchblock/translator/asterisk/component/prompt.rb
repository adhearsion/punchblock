# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Prompt < Component
          include StopByRedirect

          UniMRCPError = Class.new Punchblock::Error

          def execute
            validate
            send_ref
            execute_synthandrecog
            complete
          rescue UniMRCPError
            complete_with_error 'Terminated due to UniMRCP error'
          rescue RubyAMI::Error => e
            complete_with_error "Terminated due to AMI error '#{e.message}'"
          rescue OptionError => e
            with_error 'option error', e.message
          end

          private

          def validate
            raise OptionError, "The renderer #{renderer} is unsupported." unless renderer == 'unimrcp'
            raise OptionError, "The recognizer #{recognizer} is unsupported." unless recognizer == 'unimrcp'
            raise OptionError, 'An SSML document is required.' unless output_node.render_documents.first.value
          end

          def renderer
            (output_node.renderer || :unimrcp).to_s
          end

          def recognizer
            (input_node.recognizer || :unimrcp).to_s
          end

          def execute_synthandrecog
            @call.execute_agi_command 'EXEC SynthAndRecog', [render_doc, grammar, synthandrecog_options].map { |o| "\"#{o.to_s.squish.gsub('"', '\"')}\"" }.join(',')
            raise UniMRCPError if @call.channel_var('RECOG_STATUS') == 'ERROR'
          end

          def render_doc
            output_node.render_documents.first.value.to_doc
          end

          def grammar
            input_node.grammars.first.value.to_doc
          end

          def synthandrecog_options
            ''
          end

          def output_node
            @component_node.output
          end

          def input_node
            @component_node.input
          end

          def complete
            case @call.channel_var('RECOG_COMPLETION_CAUSE')
            when '000' then send_match
            when '001'
              send_complete_event Punchblock::Component::Input::Complete::NoMatch.new
            when '002'
              send_complete_event Punchblock::Component::Input::Complete::InitialTimeout.new
            end
          end

          def send_match
            nlsml = RubySpeech.parse @call.channel_var('RECOG_RESULT')
            match_reason = Punchblock::Component::Input::Complete::Match.new nlsml: nlsml
            send_complete_event match_reason
          end
        end
      end
    end
  end
end
