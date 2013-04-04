# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        class InlineComponent
          include DeadActorSafety
          include HasGuardedHandlers

          attr_reader :id, :call, :call_id

          def initialize(component_node, call)
            @component_node, @call = component_node, call
            @call_id = safe_from_dead_actors { call.id } if call
            @id = Punchblock.new_uuid
            @complete = false
            setup
          end

          def setup
          end

          def execute_command(command)
            command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command for component #{id}", call_id, id
          end

          def handle_es_event(event)
            trigger_handler :es, event
          end

          def send_complete_event(reason, recording = nil)
            return if @complete
            @complete = true
            event = Punchblock::Event::Complete.new.tap do |c|
              c.reason = reason
              c << recording if recording
            end
            send_event event
          end

          def send_event(event)
            event.component_id    = id
            event.target_call_id  = call_id
            safe_from_dead_actors { translator.handle_pb_event event }
          end

          def logger_id
            "#{self.class}: #{call_id ? "Call ID: #{call_id}, Component ID: #{id}" : id}"
          end

          def call_ended
            send_complete_event Punchblock::Event::Complete::Hangup.new
          end

          def application(appname, options = nil)
            call.application appname, "%[punchblock_component_id=#{id}]#{options}"
          end

          def alive?
            true
          end

          private

          def translator
            call.translator
          end

          def set_node_response(value)
            @component_node.response = value
          end

          def send_ref
            set_node_response Ref.new :id => id
          end

          def with_error(name, text)
            set_node_response ProtocolError.new.setup(name, text)
          end
        end
      end
    end
  end
end
