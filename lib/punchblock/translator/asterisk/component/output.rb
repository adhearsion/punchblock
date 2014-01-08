# encoding: utf-8

require 'active_support/core_ext/string/filters'
require 'punchblock/translator/asterisk/unimrcp_app'

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Output < Component
          include StopByRedirect

          UnrenderableDocError  = Class.new OptionError
          UniMRCPError          = Class.new Punchblock::Error
          PlaybackError         = Class.new Punchblock::Error

          def execute
            raise OptionError, 'An SSML document is required.' unless @component_node.render_documents.first.value
            raise OptionError, 'Only a single document is supported.' unless @component_node.render_documents.size == 1
            raise OptionError, 'An interrupt-on value of speech is unsupported.' if @component_node.interrupt_on == :voice

            [:start_offset, :start_paused, :repeat_interval, :repeat_times, :max_time].each do |opt|
              raise OptionError, "A #{opt} value is unsupported on Asterisk." if @component_node.send opt
            end

            early = !@call.answered?

            rendering_engine = @component_node.renderer || :asterisk

            case rendering_engine.to_sym
            when :asterisk
              raise OptionError, "A voice value is unsupported on Asterisk." if @component_node.voice
              raise OptionError, 'Interrupt digits are not allowed with early media.' if early && @component_node.interrupt_on

              case @component_node.interrupt_on
              when :any, :dtmf
                interrupt = true
              end

              path = filenames.join '&'

              @call.send_progress if early

              if interrupt
                call.register_handler :ami, :name => 'DTMF', [:[], 'End'] => 'Yes' do |event|
                  stop_by_redirect finish_reason
                end
              end

              send_ref

              opts = early ? "#{path},noanswer" : path
              @call.execute_agi_command 'EXEC Playback', opts
              raise PlaybackError if @call.channel_var('PLAYBACKSTATUS') == 'FAILED'
            when :unimrcp
              @call.send_progress if early
              send_ref
              UniMRCPApp.new('MRCPSynth', render_doc, mrcpsynth_options).execute @call
              raise UniMRCPError if @call.channel_var('SYNTHSTATUS') == 'ERROR'
            when :swift
              @call.send_progress if early
              send_ref
              @call.execute_agi_command 'EXEC Swift', swift_doc
            else
              raise OptionError, "The renderer #{rendering_engine} is unsupported."
            end
            send_finish
          rescue ChannelGoneError
            call_ended
          rescue PlaybackError
            complete_with_error 'Terminated due to playback error'
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
            @filenames ||= render_doc.children.map do |node|
              case node
              when RubySpeech::SSML::Audio
                node.src.sub('file://', '').gsub(/\.[^\.]*$/, '')
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

          def render_doc
            @component_node.render_documents.first.value
          end

          def mrcpsynth_options
            {}.tap do |opts|
              opts[:i] = 'any' if [:any, :dtmf].include? @component_node.interrupt_on
              opts[:v] = @component_node.voice if @component_node.voice
            end
          end

          def swift_doc
            doc = render_doc.to_s.squish.gsub(/["\\]/) { |m| "\\#{m}" }
            doc << "|1|1" if [:any, :dtmf].include? @component_node.interrupt_on
            doc.insert 0, "#{@component_node.voice}^" if @component_node.voice
            doc
          end

          def send_finish
            send_complete_event finish_reason
          end

          def finish_reason
            Punchblock::Component::Output::Complete::Finish.new
          end
        end
      end
    end
  end
end
