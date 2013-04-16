# encoding: utf-8

require 'active_support/core_ext/string/filters'

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Output < Component
          include StopByRedirect

          UnrenderableDocError  = Class.new OptionError
          UniMRCPError          = Class.new Punchblock::Error

          def setup
            @media_engine = @call.translator.media_engine
          end

          def execute
            raise OptionError, 'An SSML document is required.' unless @component_node.ssml
            raise OptionError, 'An interrupt-on value of speech is unsupported.' if @component_node.interrupt_on == :speech

            [:start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
              raise OptionError, "A #{opt} value is unsupported on Asterisk." if @component_node.send opt
            end

            early = !@call.answered?

            rendering_engine = @component_node.renderer || @media_engine || :asterisk

            case rendering_engine.to_sym
            when :asterisk
              raise OptionError, "A voice value is unsupported on Asterisk." if @component_node.voice
              raise OptionError, 'Interrupt digits are not allowed with early media.' if early && @component_node.interrupt_on

              case @component_node.interrupt_on
              when :any, :dtmf
                interrupt = true
              end

              path = filenames.join '&'

              send_ref

              @call.send_progress if early

              if interrupt
                output_component = current_actor
                call.register_handler :ami, :name => 'DTMF', [:[], 'End'] => 'Yes' do |event|
                  output_component.stop_by_redirect Punchblock::Component::Output::Complete::Success.new
                end
              end

              opts = early ? "#{path},noanswer" : path
              @call.execute_agi_command 'EXEC Playback', opts
            when :unimrcp
              send_ref
              @call.execute_agi_command 'EXEC MRCPSynth', escape_commas(escaped_doc), mrcpsynth_options
              raise UniMRCPError if @call.channel_var('SYNTHSTATUS') == 'ERROR'
            when :swift
              send_ref
              @call.execute_agi_command 'EXEC Swift', swift_doc
            else
              raise OptionError, "The renderer #{rendering_engine} is unsupported."
            end
            send_success
          rescue UniMRCPError
            complete_with_error 'Terminated due to UniMRCP error'
          rescue RubyAMI::Error => e
            complete_with_error "Terminated due to AMI error '#{e.message}'"
          rescue UnrenderableDocError => e
            with_error 'unrenderable document error', e.message
          rescue OptionError => e
            with_error 'option error', e.message
          end

          private

          def filenames
            @filenames ||= @component_node.ssml.children.map do |node|
              case node
              when RubySpeech::SSML::Audio
                node.src
              when String
                raise if node.include?(' ')
                node
              else
                raise
              end
            end.compact
          rescue
            raise UnrenderableDocError, 'The provided document could not be rendered. See http://adhearsion.com/docs/common_problems#unrenderable-document-error for details.'
          end

          def escaped_doc
            @component_node.ssml.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }
          end

          def escape_commas(text)
            text.gsub(',', '\\,')
          end

          def mrcpsynth_options
            [].tap do |opts|
              opts << 'i=any' if [:any, :dtmf].include? @component_node.interrupt_on
              opts << "v=#{@component_node.voice}" if @component_node.voice
            end.join '&'
          end

          def swift_doc
            doc = escaped_doc
            doc << "|1|1" if [:any, :dtmf].include? @component_node.interrupt_on
            doc.insert 0, "#{@component_node.voice}^" if @component_node.voice
            doc
          end

          def send_success
            send_complete_event success_reason
          end

          def success_reason
            Punchblock::Component::Output::Complete::Success.new
          end
        end
      end
    end
  end
end
