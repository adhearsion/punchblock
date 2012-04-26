# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        class Record < Component
          RECORDING_BASE_PATH = '/var/punchblock/record'

          def execute
            raise OptionError, 'A start-paused value of true is unsupported.' if @component_node.start_paused
            raise OptionError, 'A start-beep value of true is unsupported.' if @component_node.start_beep
            raise OptionError, 'An initial-timeout value is unsupported.' if @component_node.initial_timeout && @component_node.initial_timeout != -1
            raise OptionError, 'A final-timeout value is unsupported.' if @component_node.final_timeout && @component_node.final_timeout != -1
            raise OptionError, 'A max-duration value is unsupported.' if @component_node.max_duration && @component_node.max_duration != -1

            @format = @component_node.format || 'wav'

            @call.answer_if_not_answered

            component = current_actor
            call.register_handler :ami, :name => 'MonitorStop' do |event|
              component.finished
            end

            call.send_ami_action! 'Monitor', 'Channel' => call.channel, 'File' => filename, 'Format' => @format, 'Mix' => true
            send_ref
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
            send_complete_event (@complete_reason || success_reason), recording
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

          def success_reason
            Punchblock::Component::Record::Complete::Success.new
          end
        end
      end
    end
  end
end
