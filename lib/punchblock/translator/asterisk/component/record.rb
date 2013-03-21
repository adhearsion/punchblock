# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Record < Component
          RECORDING_BASE_PATH = '/var/punchblock/record'

          def setup
            @complete_reason = nil
          end

          def execute
            max_duration = @component_node.max_duration || -1

            raise OptionError, 'Record cannot be used on a call that is not answered.' unless @call.answered?
            raise OptionError, 'A start-paused value of true is unsupported.' if @component_node.start_paused
            raise OptionError, 'An initial-timeout value is unsupported.' if @component_node.initial_timeout && @component_node.initial_timeout != -1
            raise OptionError, 'A final-timeout value is unsupported.' if @component_node.final_timeout && @component_node.final_timeout != -1
            raise OptionError, 'A max-duration value that is negative (and not -1) is invalid.' unless max_duration >= -1

            @format = @component_node.format || 'wav'


            component = current_actor
            call.register_tmp_handler :ami, :name => 'MonitorStop' do |event|
              component.finished
            end

            send_ref

            if @component_node.start_beep
              @call.send_agi_action! 'STREAM FILE', 'beep', '""' do
                component.signal! :beep_finished
              end
              wait :beep_finished
            end

            call.send_ami_action! 'Monitor', 'Channel' => call.channel, 'File' => filename, 'Format' => @format, 'Mix' => true
            unless max_duration == -1
              after max_duration/1000 do
                call.send_ami_action! 'StopMonitor', 'Channel' => call.channel
              end
            end
          rescue OptionError => e
            with_error 'option error', e.message
          end

          def execute_command(command)
            case command
            when Punchblock::Component::Stop
              command.response = true
              a = current_actor
              call.send_ami_action! 'StopMonitor', 'Channel' => call.channel do |complete_event|
                @complete_reason = stop_reason
              end
            when Punchblock::Component::Record::Pause
              a = current_actor
              call.send_ami_action! 'PauseMonitor', 'Channel' => call.channel do |complete_event|
                command.response = true
              end
            when Punchblock::Component::Record::Resume
              a = current_actor
              call.send_ami_action! 'ResumeMonitor', 'Channel' => call.channel do |complete_event|
                command.response = true
              end
            else
              super
            end
          end

          def finished
            send_complete_event(@complete_reason || max_duration_reason)
          end

          private

          def filename
            File.join RECORDING_BASE_PATH, id
          end

          def recording
            Punchblock::Component::Record::Recording.new :uri => "file://#{filename}.#{@format}"
          end

          def stop_reason
            Punchblock::Event::Complete::Stop.new
          end

          def max_duration_reason
            Punchblock::Component::Record::Complete::MaxDuration.new
          end

          def send_complete_event(reason)
            super reason, recording
          end
        end
      end
    end
  end
end
