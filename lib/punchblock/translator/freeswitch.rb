# encoding: utf-8

require 'celluloid'

module Punchblock
  module Translator
    class Freeswitch
      include Celluloid
      include HasGuardedHandlers

      extend ActiveSupport::Autoload

      # autoload :Call
      # autoload :Component

      attr_reader :connection#, :calls

      def initialize(connection)
        pb_logger.debug "Starting up..."
        @connection = connection
        # @calls, @components, @channel_to_call_id = {}, {}, {}
        setup_handlers
      end

      # def register_call(call)
      #   @channel_to_call_id[call.channel] = call.id
      #   @calls[call.id] ||= call
      # end

      # def deregister_call(call)
      #   @channel_to_call_id[call.channel] = nil
      #   @calls[call.id] = nil
      # end

      # def call_with_id(call_id)
      #   @calls[call_id]
      # end

      # def call_for_channel(channel)
      #   call_with_id @channel_to_call_id[channel]
      # end

      # def register_component(component)
      #   @components[component.id] ||= component
      # end

      # def component_with_id(component_id)
      #   @components[component_id]
      # end

      def setup_handlers
        register_handler :es, :event => 'CHANNEL_PARK' do
          pb_logger.info "A channel was parked1"
        end
      end

      def shutdown
        pb_logger.debug "Shutting down"
        # @calls.values.each(&:shutdown!)
        terminate
      end

      def handle_es_event(event)
        pb_logger.trace "Received event #{event.inspect}"
        trigger_handler :es, event
      end

      # def handle_ami_event(event)
      #   exclusive do
      #     return unless event.is_a? RubyAMI::Event

      #     if event.name.downcase == "fullybooted"
      #       pb_logger.trace "Counting FullyBooted event"
      #       @fully_booted_count += 1
      #       if @fully_booted_count >= 2
      #         handle_pb_event Connection::Connected.new
      #         @fully_booted_count = 0
      #         run_at_fully_booted
      #       end
      #       return
      #     end

      #     handle_varset_ami_event event

      #     ami_dispatch_to_or_create_call event

      #     unless ami_event_known_call?(event)
      #       handle_pb_event Event::Asterisk::AMI::Event.new(:name => event.name, :attributes => event.headers)
      #     end
      #   end
      # end

      def handle_pb_event(event)
        connection.handle_event event
      end

      # def execute_command(command, options = {})
      #   pb_logger.trace "Executing command #{command.inspect}"
      #   command.request!

      #   command.target_call_id ||= options[:call_id]
      #   command.component_id ||= options[:component_id]

      #   if command.target_call_id
      #     execute_call_command command
      #   elsif command.component_id
      #     execute_component_command command
      #   else
      #     execute_global_command command
      #   end
      # end

      # def execute_call_command(command)
      #   if call = call_with_id(command.target_call_id)
      #     call.execute_command! command
      #   else
      #     command.response = ProtocolError.new.setup 'item-not-found', "Could not find a call with ID #{command.target_call_id}", command.target_call_id
      #   end
      # end

      # def execute_component_command(command)
      #   if (component = component_with_id(command.component_id))
      #     component.execute_command! command
      #   else
      #     command.response = ProtocolError.new.setup 'item-not-found', "Could not find a component with ID #{command.component_id}", command.target_call_id, command.component_id
      #   end
      # end

      # def execute_global_command(command)
      #   case command
      #   when Punchblock::Component::Asterisk::AMI::Action
      #     component = Component::Asterisk::AMIAction.new command, current_actor
      #     register_component component
      #     component.execute!
      #   when Punchblock::Command::Dial
      #     call = Call.new command.to, current_actor
      #     register_call call
      #     call.dial! command
      #   else
      #     command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command"
      #   end
      # end

      # private

      # def ami_dispatch_to_or_create_call(event)
      #   if ami_event_known_call?(event)
      #     channels_for_ami_event(event).each do |channel|
      #       call = call_for_channel channel
      #       call.process_ami_event! event if call
      #     end
      #   elsif event.name.downcase == "asyncagi" && event['SubEvent'] == "Start"
      #     handle_async_agi_start_event event
      #   end
      # end

      # def channels_for_ami_event(event)
      #   [event['Channel'], event['Channel1'], event['Channel2']].compact
      # end

      # def ami_event_known_call?(event)
      #   (event['Channel'] && call_for_channel(event['Channel'])) ||
      #     (event['Channel1'] && call_for_channel(event['Channel1'])) ||
      #     (event['Channel2'] && call_for_channel(event['Channel2']))
      # end

      # def handle_async_agi_start_event(event)
      #   env = Call.parse_environment event['Env']

      #   return pb_logger.warn "Ignoring AsyncAGI Start event because it is for an 'h' extension" if env[:agi_extension] == 'h'
      #   return pb_logger.warn "Ignoring AsyncAGI Start event because it is for an 'Kill' type" if env[:agi_type] == 'Kill'

      #   pb_logger.trace "Handling AsyncAGI Start event by creating a new call"
      #   call = Call.new event['Channel'], current_actor, env
      #   register_call call
      #   call.send_offer!
      # end
    end
  end
end
