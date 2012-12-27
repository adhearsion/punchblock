# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class Record < Component
          RECORDING_BASE_PATH = '/var/punchblock/record'

          def setup
            @complete_reason = nil
          end

          def execute
            max_duration = @component_node.max_duration || -1

            raise OptionError, 'A start-beep value of true is unsupported.' if @component_node.start_beep
            raise OptionError, 'A start-paused value of true is unsupported.' if @component_node.start_paused
            raise OptionError, 'An initial-timeout value is unsupported.' if @component_node.initial_timeout && @component_node.initial_timeout != -1
            raise OptionError, 'A final-timeout value is unsupported.' if @component_node.final_timeout && @component_node.final_timeout != -1
            raise OptionError, 'A max-duration value that is negative (and not -1) is invalid.' unless max_duration >= -1

            @format = @component_node.format || 'wav'

            component = current_actor
            call.register_handler :es, :event_name => 'RECORD_STOP', [:[], :record_file_path] => filename do |event|
              component.finished
            end

            record_args = ['start', filename]
            record_args << max_duration/1000 unless max_duration == -1
            if @component_node.direction == :duplex
              call.stream.bgapi "record_session #{filename}"
            else
              call.uuid_foo :record, record_args.join(' ')
            end
            send_ref
          rescue OptionError => e
            with_error 'option error', e.message
          end

          def execute_command(command)
            case command
            when Punchblock::Component::Stop
              if @component_node.direction == :duplex
                call.stream.bgapi "stop_record_session #{filename}"
              else
                call.uuid_foo :record, "stop #{filename}"
              end
              @complete_reason = stop_reason
              command.response = true
            else
              super
            end
          end

          def finished
            send_complete_event(@complete_reason || success_reason)
          end

          private

          def filename
            File.join RECORDING_BASE_PATH, [id, @format].join('.')
          end

          def recording
            Punchblock::Component::Record::Recording.new :uri => "file://#{filename}"
          end

          def stop_reason
            Punchblock::Event::Complete::Stop.new
          end

          def success_reason
            Punchblock::Component::Record::Complete::Success.new
          end

          def send_complete_event(reason)
            super reason, recording
          end
        end
      end
    end
  end
end
