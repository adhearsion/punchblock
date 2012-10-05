# encoding: utf-8

module Punchblock
  module Translator
    class Freeswitch
      class Call
        include HasGuardedHandlers
        include Celluloid
        include DeadActorSafety

        HANGUP_CAUSE_TO_END_REASON = Hash.new :error

        HANGUP_CAUSE_TO_END_REASON['USER_BUSY'] = :busy

        %w{
          NORMAL_CLEARING ORIGINATOR_CANCEL SYSTEM_SHUTDOWN MANAGER_REQUEST
          BLIND_TRANSFER ATTENDED_TRANSFER PICKED_OFF NORMAL_UNSPECIFIED
        }.each { |c| HANGUP_CAUSE_TO_END_REASON[c] = :hangup }

        %w{
          NO_USER_RESPONSE NO_ANSWER SUBSCRIBER_ABSENT ALLOTTED_TIMEOUT
          MEDIA_TIMEOUT PROGRESS_TIMEOUT
        }.each { |c| HANGUP_CAUSE_TO_END_REASON[c] = :timeout }

        %w{CALL_REJECTED NUMBER_CHANGED
          REDIRECTION_TO_NEW_DESTINATION FACILITY_REJECTED NORMAL_CIRCUIT_CONGESTION
          SWITCH_CONGESTION USER_NOT_REGISTERED FACILITY_NOT_SUBSCRIBED
          OUTGOING_CALL_BARRED INCOMING_CALL_BARRED BEARERCAPABILITY_NOTAUTH
          BEARERCAPABILITY_NOTAVAIL SERVICE_UNAVAILABLE BEARERCAPABILITY_NOTIMPL
          CHAN_NOT_IMPLEMENTED FACILITY_NOT_IMPLEMENTED SERVICE_NOT_IMPLEMENTED
        }.each { |c| HANGUP_CAUSE_TO_END_REASON[c] = :reject }

        REJECT_TO_HANGUP_REASON = Hash.new 'NORMAL_TEMPORARY_FAILURE'
        REJECT_TO_HANGUP_REASON.merge! :busy => 'USER_BUSY', :decline => 'CALL_REJECTED'

        attr_reader :id, :translator, :es_env, :direction, :stream, :media_engine, :default_voice

        trap_exit :actor_died

        def initialize(id, translator, es_env = nil, stream = nil, media_engine = nil, default_voice = nil)
          @id, @translator, @stream, @media_engine, @default_voice = id, translator, stream, media_engine, default_voice
          @es_env = es_env || {}
          @components = {}
          @pending_joins, @pending_unjoins = {}, {}
          @answered = false
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

        def to_s
          "#<#{self.class}:#{id}>"
        end
        alias :inspect :to_s

        def setup_handlers
          register_handler :es, :event_name => 'CHANNEL_ANSWER' do
            @answered = true
            send_pb_event Event::Answered.new
          end

          register_handler :es, :event_name => 'CHANNEL_STATE', [:[], :channel_call_state] => 'RINGING' do
            send_pb_event Event::Ringing.new
          end

          register_handler :es, :event_name => 'CHANNEL_HANGUP' do |event|
            @components.dup.each_pair do |id, component|
              safe_from_dead_actors do
                component.call_ended if component.alive?
              end
            end
            send_end_event HANGUP_CAUSE_TO_END_REASON[event[:hangup_cause]]
          end

          register_handler :es, :event_name => 'CHANNEL_BRIDGE' do |event|
            command = @pending_joins[event[:other_leg_unique_id]]
            command.response = true if command

            other_call_id = event[:unique_id] == id ? event[:other_leg_unique_id] : event[:unique_id]
            send_pb_event Event::Joined.new(:call_id => other_call_id)
          end

          register_handler :es, :event_name => 'CHANNEL_UNBRIDGE' do |event|
            command = @pending_unjoins[event[:other_leg_unique_id]]
            command.response = true if command

            other_call_id = event[:unique_id] == id ? event[:other_leg_unique_id] : event[:unique_id]
            send_pb_event Event::Unjoined.new(:call_id => other_call_id)
          end


          register_handler :es, [:has_key?, :scope_variable_punchblock_component_id] => true do |event|
            if component = component_with_id(event[:scope_variable_punchblock_component_id])
              safe_from_dead_actors { component.handle_es_event event if component.alive? }
            end
          end
        end

        def handle_es_event(event)
          trigger_handler :es, event
        end

        def application(*args)
          stream.application id, *args
        end

        def sendmsg(*args)
          stream.sendmsg id, *args
        end

        def uuid_foo(app, args = '')
          stream.bgapi "uuid_#{app} #{id} #{args}"
        end

        def dial(dial_command)
          @direction = :outbound

          cid_number, cid_name = dial_command.from, nil
          dial_command.from.match(/(?<cid_name>.*)<(?<cid_number>.*)>/) do |m|
            cid_name = m[:cid_name].strip
            cid_number = m[:cid_number]
          end

          options = {
            :return_ring_ready  => true,
            :origination_uuid   => id
          }
          options[:origination_caller_id_number] = "'#{cid_number}'" if cid_number.present?
          options[:origination_caller_id_name] = "'#{cid_name}'" if cid_name.present?
          options[:originate_timeout] = dial_command.timeout/1000 if dial_command.timeout
          opts = options.inject([]) do |a, (k, v)|
            a << "#{k}=#{v}"
          end.join(',')

          stream.bgapi "originate {#{opts}}#{dial_command.to} &park()"

          dial_command.response = Ref.new :id => id
        end

        def outbound?
          direction == :outbound
        end

        def inbound?
          direction == :inbound
        end

        def answered?
          @answered
        end

        def execute_command(command)
          if command.component_id
            if component = component_with_id(command.component_id)
              component.execute_command command
            else
              command.response = ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
            end
          end
          case command
          when Command::Accept
            application 'respond', '180 Ringing'
            command.response = true
          when Command::Answer
            command_id = Punchblock.new_uuid
            register_tmp_handler :es, :event_name => 'CHANNEL_ANSWER', [:[], :scope_variable_punchblock_command_id] => command_id do
              @answered = true
              command.response = true
            end
            application 'answer', "%[punchblock_command_id=#{command_id}]"
          when Command::Hangup
            hangup
            command.response = true
          when Command::Join
            @pending_joins[command.call_id] = command
            uuid_foo :bridge, command.call_id
          when Command::Unjoin
            @pending_unjoins[command.call_id] = command
            uuid_foo :transfer, '-both park inline'
          when Command::Reject
            hangup REJECT_TO_HANGUP_REASON[command.reason]
            command.response = true
          when Punchblock::Component::Output
            case media_engine
            when :freeswitch, :native, nil
              execute_component Component::Output, command
            when :flite
              execute_component Component::FliteOutput, command, media_engine, default_voice
            else
              execute_component Component::TTSOutput, command, media_engine, default_voice
            end
          when Punchblock::Component::Input
            execute_component Component::Input, command
          when Punchblock::Component::Record
            execute_component Component::Record, command
          else
            command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command for call #{id}", id
          end
        end

        def hangup(reason = 'NORMAL_CLEARING')
          sendmsg :call_command => 'hangup', :hangup_cause => reason
        end

        def logger_id
          "#{self.class}: #{id}"
        end

        def actor_died(actor, reason)
          return unless reason
          pb_logger.error "A linked actor (#{actor.inspect}) died due to #{reason.inspect}"
          if id = @components.key(actor)
            @components.delete id
            complete_event = Punchblock::Event::Complete.new :component_id => id, :reason => Punchblock::Event::Complete::Error.new
            send_pb_event complete_event
          end
        end

        private

        def send_end_event(reason)
          send_pb_event Event::End.new(:reason => reason)
          translator.deregister_call current_actor
          after(5) { terminate }
        end

        def execute_component(type, command, *execute_args)
          type.new_link(command, current_actor).tap do |component|
            register_component component
            component.execute!(*execute_args)
          end
        end

        def send_pb_event(event)
          event.target_call_id = id
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
