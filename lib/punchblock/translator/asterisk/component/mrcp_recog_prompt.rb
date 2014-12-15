# encoding: utf-8

require 'punchblock/translator/asterisk/unimrcp_app'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module MRCPRecogPrompt
          UniMRCPError = Class.new Punchblock::Error

          def execute
            setup_defaults
            validate
            send_ref
            execute_unimrcp_app
            complete
          rescue ChannelGoneError
            call_ended
          rescue UniMRCPError
            complete_with_error 'Terminated due to UniMRCP error'
          rescue RubyAMI::Error => e
            complete_with_error "Terminated due to AMI error '#{e.message}'"
          rescue OptionError => e
            with_error 'option error', e.message
          end

          private

          def validate
            [:interrupt_on, :start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
              raise OptionError, "A #{opt} value is unsupported on Asterisk." if output_node.send opt
            end

            raise OptionError, "An initial-timeout value must be -1 or a positive integer." if @initial_timeout < -1
            raise OptionError, "An inter-digit-timeout value must be -1 or a positive integer." if @inter_digit_timeout < -1
            raise OptionError, "A recognition-timeout value must be -1, 0, or a positive integer." if @recognition_timeout < -1
          end

          def execute_app(app, *args)
            UniMRCPApp.new(app, *args, unimrcp_app_options).execute @call
          end

          def unimrcp_app_options
            {uer: 1, b: (@component_node.barge_in == false ? 0 : 1)}.tap do |opts|
              opts[:nit] = @initial_timeout if @initial_timeout > -1
              opts[:dit] = @inter_digit_timeout if @inter_digit_timeout > -1
              opts[:dttc] = input_node.terminator if input_node.terminator
              opts[:spl] = input_node.language if input_node.language
              opts[:ct] = input_node.min_confidence if input_node.min_confidence
              opts[:sl] = input_node.sensitivity if input_node.sensitivity
              opts[:t]  = input_node.recognition_timeout if @recognition_timeout > -1
              yield opts
            end
          end

          def setup_defaults
            @initial_timeout = input_node.initial_timeout || -1
            @inter_digit_timeout = input_node.inter_digit_timeout || -1
            @recognition_timeout = input_node.recognition_timeout || -1
          end

          def grammars
            input_node.grammars.map do |d|
              if d.content_type
                d.value.to_doc.to_s
              else
                d.url
              end
            end.join ','
          end

          def first_doc
            output_node.render_documents.first
          end

          def audio_filename
            first_doc.value.first
          end

          def output_node
            @component_node.output
          end

          def input_node
            @component_node.input
          end

          def complete
            case @call.channel_var('RECOG_STATUS') 
            when 'INTERRUPTED'
              send_complete_event Punchblock::Component::Input::Complete::NoMatch.new
            when 'ERROR'
              raise UniMRCPError
            else 
              send_complete_event case @call.channel_var('RECOG_COMPLETION_CAUSE')
              when '000', '008', '012'
                nlsml = RubySpeech.parse URI.decode(@call.channel_var('RECOG_RESULT'))
                Punchblock::Component::Input::Complete::Match.new nlsml: nlsml
              when '001', '003', '013', '014', '015'
                Punchblock::Component::Input::Complete::NoMatch.new
              when '002', '011'
                Punchblock::Component::Input::Complete::NoInput.new
              when '004', '005', '006', '007', '009', '010', '016'
                raise UniMRCPError
              else
                raise UniMRCPError
              end
            end
          end
        end
      end
    end
  end
end
