# encoding: utf-8

# require 'uri'
require 'uuidtools'

module Punchblock
  module Translator
    class Freeswitch
      class Call
        include HasGuardedHandlers
        include Celluloid
        include DeadActorSafety

        HANGUP_CAUSE_TO_END_REASON = Hash.new { :error }

        HANGUP_CAUSE_TO_END_REASON['USER_BUSY']           = :busy
        HANGUP_CAUSE_TO_END_REASON['NORMAL_CLEARING']     = :hangup
        HANGUP_CAUSE_TO_END_REASON['ORIGINATOR_CANCEL']   = :hangup
        HANGUP_CAUSE_TO_END_REASON['SYSTEM_SHUTDOWN']     = :hangup
        HANGUP_CAUSE_TO_END_REASON['MANAGER_REQUEST']     = :hangup
        HANGUP_CAUSE_TO_END_REASON['BLIND_TRANSFER']      = :hangup
        HANGUP_CAUSE_TO_END_REASON['ATTENDED_TRANSFER']   = :hangup
        HANGUP_CAUSE_TO_END_REASON['PICKED_OFF']          = :hangup
        HANGUP_CAUSE_TO_END_REASON['NORMAL_UNSPECIFIED']  = :hangup

        HANGUP_CAUSE_TO_END_REASON['NO_USER_RESPONSE']  = :timeout
        HANGUP_CAUSE_TO_END_REASON['NO_ANSWER']         = :timeout
        HANGUP_CAUSE_TO_END_REASON['SUBSCRIBER_ABSENT'] = :timeout
        HANGUP_CAUSE_TO_END_REASON['ALLOTTED_TIMEOUT']  = :timeout
        HANGUP_CAUSE_TO_END_REASON['MEDIA_TIMEOUT']     = :timeout
        HANGUP_CAUSE_TO_END_REASON['PROGRESS_TIMEOUT']  = :timeout

        HANGUP_CAUSE_TO_END_REASON['CALL_REJECTED']                   = :reject
        HANGUP_CAUSE_TO_END_REASON['NUMBER_CHANGED']                  = :reject
        HANGUP_CAUSE_TO_END_REASON['REDIRECTION_TO_NEW_DESTINATION']  = :reject
        HANGUP_CAUSE_TO_END_REASON['FACILITY_REJECTED']               = :reject
        HANGUP_CAUSE_TO_END_REASON['NORMAL_CIRCUIT_CONGESTION']       = :reject
        HANGUP_CAUSE_TO_END_REASON['SWITCH_CONGESTION']               = :reject
        HANGUP_CAUSE_TO_END_REASON['USER_NOT_REGISTERED']             = :reject
        HANGUP_CAUSE_TO_END_REASON['FACILITY_NOT_SUBSCRIBED']         = :reject
        HANGUP_CAUSE_TO_END_REASON['OUTGOING_CALL_BARRED']            = :reject
        HANGUP_CAUSE_TO_END_REASON['INCOMING_CALL_BARRED']            = :reject
        HANGUP_CAUSE_TO_END_REASON['BEARERCAPABILITY_NOTAUTH']        = :reject
        HANGUP_CAUSE_TO_END_REASON['BEARERCAPABILITY_NOTAVAIL']       = :reject
        HANGUP_CAUSE_TO_END_REASON['SERVICE_UNAVAILABLE']             = :reject
        HANGUP_CAUSE_TO_END_REASON['BEARERCAPABILITY_NOTIMPL']        = :reject
        HANGUP_CAUSE_TO_END_REASON['CHAN_NOT_IMPLEMENTED']            = :reject
        HANGUP_CAUSE_TO_END_REASON['FACILITY_NOT_IMPLEMENTED']        = :reject
        HANGUP_CAUSE_TO_END_REASON['SERVICE_NOT_IMPLEMENTED']         = :reject

        attr_reader :id, :platform_id, :translator, :es_env, :direction#, :pending_joins

        trap_exit :actor_died

        class << self
          def es_env_variables(content)
            content.select { |k,v| k.to_s =~ /variable/ }
          end
        end

        def initialize(platform_id, translator, es_env = nil)
          @platform_id, @translator = platform_id, translator
          @es_env = es_env || {}
          @id, @components = UUIDTools::UUID.random_create.to_s, {}
        #   @answered = false
          pb_logger.debug "Starting up call with platform ID #{@platform_id}, id #{@id}"
          setup_handlers
        end

        def register_component(component)
          @components[component.id] ||= component
        end

        def component_with_id(component_id)
          @components[component_id]
        end

        def send_offer
          @direction = :inbound
          send_pb_event offer_event
        end

        def shutdown
          pb_logger.debug "Shutting down"
          current_actor.terminate!
        end

        def to_s
          "#<#{self.class}:#{id} Platform ID: #{platform_id.inspect}>"
        end
        alias :inspect :to_s

        def setup_handlers
          register_handler :es, :event_name => 'CHANNEL_HANGUP' do |event|
            pb_logger.info "The channel hung up: #{event.inspect}"
            # @components.dup.each_pair do |id, component|
            #   safe_from_dead_actors do
            #     component.call_ended if component.alive?
            #   end
            # end
            send_end_event HANGUP_CAUSE_TO_END_REASON[event[:hangup_cause]]
          end
        end

        def handle_es_event(event)
          trigger_handler :es, event
        end

        def dial(dial_command)
          @direction = :outbound
        #   params = { :async       => true,
        #              :application => 'AGI',
        #              :data        => 'agi:async',
        #              :channel     => dial_command.to,
        #              :callerid    => dial_command.from,
        #              :variable    => "punchblock_call_id=#{id}"
        #            }
        #   params[:timeout] = dial_command.timeout unless dial_command.timeout.nil?

        #   originate_action = Punchblock::Component::Asterisk::AMI::Action.new :name => 'Originate',
        #                                                                       :params => params
        #   originate_action.request!
        #   translator.execute_global_command! originate_action
          dial_command.response = Ref.new :id => id
        end

        def outbound?
          direction == :outbound
        end

        def inbound?
          direction == :inbound
        end

        # def answered?
        #   @answered
        # end

        def execute_command(command)
          pb_logger.debug "Executing command: #{command.inspect}"
        #   if command.component_id
        #     if component = component_with_id(command.component_id)
        #       component.execute_command command
        #     else
        #       command.response = ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
        #     end
        #   end
          # case command
        #   when Command::Accept
        #     if outbound?
        #       pb_logger.trace "Attempting to accept an outbound call. Skipping RINGING."
        #       command.response = true
        #     else
        #       pb_logger.trace "Attempting to accept an inbound call. Executing RINGING."
        #       send_agi_action 'EXEC RINGING' do |response|
        #         command.response = true
        #       end
        #     end
        #   when Command::Answer
        #     send_agi_action 'ANSWER' do |response|
        #       command.response = true
        #     end
        #   when Command::Hangup
        #     send_ami_action 'Hangup', 'Channel' => channel do |response|
        #       command.response = true
        #     end
        #   when Command::Join
        #     other_call = translator.call_with_id command.call_id
        #     pending_joins[other_call.channel] = command
        #     send_agi_action 'EXEC Bridge', other_call.channel
        #   when Command::Unjoin
        #     other_call = translator.call_with_id command.call_id
        #     redirect_back other_call
        #   when Command::Reject
        #     rejection = case command.reason
        #     when :busy
        #       'EXEC Busy'
        #     when :decline
        #       'EXEC Busy'
        #     when :error
        #       'EXEC Congestion'
        #     else
        #       'EXEC Congestion'
        #     end
        #     send_agi_action rejection do |response|
        #       command.response = true
        #     end
        #   when Punchblock::Component::Asterisk::AGI::Command
        #     execute_component Component::Asterisk::AGICommand, command
        #   when Punchblock::Component::Output
        #     execute_component Component::Output, command
        #   when Punchblock::Component::Input
        #     execute_component Component::Input, command
        #   when Punchblock::Component::Record
        #     execute_component Component::Record, command
          # else
            command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command for call #{id}", id
          # end
        end

        def logger_id
          "#{self.class}: #{id}"
        end

        # def actor_died(actor, reason)
        #   return unless reason
        #   pb_logger.error "A linked actor (#{actor.inspect}) died due to #{reason.inspect}"
        #   if id = @components.key(actor)
        #     pb_logger.info "Dead actor was a component we know about, with ID #{id}. Removing it from the registry..."
        #     @components.delete id
        #     complete_event = Punchblock::Event::Complete.new :component_id => id, :reason => Punchblock::Event::Complete::Error.new
        #     send_pb_event complete_event
        #   end
        # end

        private

        def send_end_event(reason)
          send_pb_event Event::End.new(:reason => reason)
          translator.deregister_call current_actor
          after(5) { shutdown }
        end

        # def execute_component(type, command, options = {})
        #   type.new_link(command, current_actor).tap do |component|
        #     register_component component
        #     component.internal = true if options[:internal]
        #     component.execute!
        #   end
        # end

        def send_pb_event(event)
          event.target_call_id = id
          pb_logger.trace "Sending Punchblock event: #{event.inspect}"
          translator.handle_pb_event event
        end

        def offer_event
          Event::Offer.new :to      => es_env[:variable_sip_to_uri],
                           :from    => "#{es_env[:variable_effective_caller_id_name]} <#{es_env[:variable_sip_from_uri]}>",
                           :headers => headers
        end

        def headers
          es_env.to_a.inject({}) do |accumulator, element|
            accumulator[('x_' + element[0].to_s).to_sym] = element[1] || ''
            accumulator
          end
        end
      end
    end
  end
end
