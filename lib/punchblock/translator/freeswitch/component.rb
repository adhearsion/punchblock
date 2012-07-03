# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      module Component
        extend ActiveSupport::Autoload

        autoload :Output

        class Component
          OptionError = Class.new Punchblock::Error

          include Celluloid
          include DeadActorSafety
          include HasGuardedHandlers

          attr_reader :id, :call, :call_id

          def initialize(component_node, call = nil)
            @component_node, @call = component_node, call
            @call_id = safe_from_dead_actors { call.id } if call
            @id = UUIDTools::UUID.random_create.to_s
            @complete = false
            setup
            pb_logger.debug "Starting up..."
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
            current_actor.terminate!
          end

          def send_event(event)
            event.component_id    = id
            event.target_call_id  = call_id
            pb_logger.debug "Sending event #{event}"
            safe_from_dead_actors { translator.handle_pb_event event }
          end

          def logger_id
            "#{self.class}: #{call_id ? "Call ID: #{call_id}, Component ID: #{id}" : id}"
          end

          def call_ended
            send_complete_event Punchblock::Event::Complete::Hangup.new
          end

          def application(appname, options = nil, &block)
            call.application appname, "%[punchblock_component_id=#{id}]#{options}", &block
          end

          private

          def translator
            call.translator
          end

          def set_node_response(value)
            pb_logger.debug "Setting response on component node to #{value}"
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
