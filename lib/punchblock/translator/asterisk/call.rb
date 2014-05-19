# encoding: utf-8

require 'punchblock/translator/asterisk/ami_error_converter'

module Punchblock
  module Translator
    class Asterisk
      class Call
        include HasGuardedHandlers
        include Celluloid
        include DeadActorSafety

        extend ActorHasGuardedHandlers
        execute_guarded_handlers_on_receiver

        InvalidCommandError = Class.new Punchblock::Error

        attr_reader :id, :channel, :translator, :agi_env, :direction

        HANGUP_CAUSE_TO_END_REASON = Hash.new { :error }
        HANGUP_CAUSE_TO_END_REASON[0] = :hangup
        HANGUP_CAUSE_TO_END_REASON[16] = :hangup
        HANGUP_CAUSE_TO_END_REASON[17] = :busy
        HANGUP_CAUSE_TO_END_REASON[18] = :timeout
        HANGUP_CAUSE_TO_END_REASON[19] = :reject
        HANGUP_CAUSE_TO_END_REASON[21] = :reject
        HANGUP_CAUSE_TO_END_REASON[22] = :reject
        HANGUP_CAUSE_TO_END_REASON[102] = :timeout

        trap_exit :actor_died

        def initialize(channel, translator, ami_client, connection, agi_env = nil)
          @channel, @translator, @ami_client, @connection = channel, translator, ami_client, connection
          @agi_env = agi_env || {}
          @id, @components = Punchblock.new_uuid, {}
          @answered = false
          @pending_joins = {}
          @progress_sent = false
          @block_commands = false
          @channel_variables = {}
          @hangup_cause = nil
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
          terminate
        end

        def channel_var(variable)
          @channel_variables[variable] || fetch_channel_var(variable)
        end

        def to_s
          "#<#{self.class}:#{id} Channel: #{channel.inspect}>"
        end
        alias :inspect :to_s

        def dial(dial_command)
          @direction = :outbound
          channel = dial_command.to || ''
          channel.match(/.* <(?<channel>.*)>/) { |m| channel = m[:channel] }
          params = { :async       => true,
                     :application => 'AGI',
                     :data        => 'agi:async',
                     :channel     => channel,
                     :callerid    => dial_command.from
                   }
          params[:variable] = variable_for_headers dial_command.headers
          params[:timeout] = dial_command.timeout unless dial_command.timeout.nil?

          originate_action = Punchblock::Component::Asterisk::AMI::Action.new :name => 'Originate',
                                                                              :params => params
          originate_action.request!
          translator.async.execute_global_command originate_action
          dial_command.response = Ref.new uri: id
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

        def send_progress
          return if answered? || outbound? || @progress_sent
          @progress_sent = true
          execute_agi_command "EXEC Progress"
        end

        def channel=(other)
          @channel = other
        end

        def process_ami_event(ami_event)
          send_pb_event Event::Asterisk::AMI::Event.new(name: ami_event.name, headers: ami_event.headers)

          case ami_event.name
          when 'Hangup'
            handle_hangup_event ami_event['Cause'].to_i
          when 'AsyncAGI'
            if component = component_with_id(ami_event['CommandID'])
              component.handle_ami_event ami_event
            end
          when 'Newstate'
            case ami_event['ChannelState']
            when '5'
              send_pb_event Event::Ringing.new
            when '6'
              @answered = true
              send_pb_event Event::Answered.new
            end
          when 'OriginateResponse'
            if ami_event['Response'] == 'Failure' && ami_event['Uniqueid'] == '<null>'
              send_end_event :error
            end
          when 'BridgeExec'
            join_command   = @pending_joins.delete ami_event['Channel1']
            join_command ||= @pending_joins.delete ami_event['Channel2']
            join_command.response = true if join_command
          when 'Bridge'
            other_call_channel = ([ami_event['Channel1'], ami_event['Channel2']] - [channel]).first
            if other_call = translator.call_for_channel(other_call_channel)
              event = case ami_event['Bridgestate']
              when 'Link'
                Event::Joined.new call_uri: other_call.id
              when 'Unlink'
                Event::Unjoined.new call_uri: other_call.id
              end
              send_pb_event event
            end
          when 'Unlink'
            other_call_channel = ([ami_event['Channel1'], ami_event['Channel2']] - [channel]).first
            if other_call = translator.call_for_channel(other_call_channel)
              send_pb_event Event::Unjoined.new(call_uri: other_call.id)
            end
          when 'VarSet'
            @channel_variables[ami_event['Variable']] = ami_event['Value']
          end
          trigger_handler :ami, ami_event
        end

        def execute_command(command)
          if @block_commands
            command.response = ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{id}", id
            return
          end
          if command.component_id
            if component = component_with_id(command.component_id)
              component.execute_command command
            else
              command.response = ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
            end
          end
          case command
          when Command::Accept
            if outbound?
              command.response = true
            else
              execute_agi_command 'EXEC RINGING'
              command.response = true
            end
          when Command::Answer
            execute_agi_command 'ANSWER'
            @answered = true
            command.response = true
          when Command::Hangup
            send_hangup_command
            @hangup_cause = :hangup_command
            command.response = true
          when Command::Join
            other_call = translator.call_with_id command.call_uri
            @pending_joins[other_call.channel] = command
            execute_agi_command 'EXEC Bridge', other_call.channel
          when Command::Unjoin
            other_call = translator.call_with_id command.call_uri
            redirect_back other_call
            command.response = true
          when Command::Reject
            case command.reason
            when :busy
              execute_agi_command 'EXEC Busy'
            when :decline
              send_hangup_command 21
            when :error
              execute_agi_command 'EXEC Congestion'
            else
              execute_agi_command 'EXEC Congestion'
            end
            command.response = true
          when Punchblock::Component::Asterisk::AGI::Command
            execute_component Component::Asterisk::AGICommand, command
          when Punchblock::Component::Output
            execute_component Component::Output, command
          when Punchblock::Component::Input
            execute_component Component::Input, command
          when Punchblock::Component::Prompt
            component_class = determine_component_class(command)
            execute_component component_class, command
          when Punchblock::Component::Record
            execute_component Component::Record, command
          else
            command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command for call #{id}", id
          end
        rescue InvalidCommandError => e
          command.response = ProtocolError.new.setup :invalid_command, e.message, id
        rescue ChannelGoneError
          command.response = ProtocolError.new.setup :item_not_found, "Could not find a call with ID #{id}", id
        rescue RubyAMI::Error => e
          command.response = ProtocolError.new.setup 'error', e.message, id
        rescue Celluloid::DeadActorError
          command.response = ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
        end

        def determine_component_class(command)
          if command.input.recognizer === 'unimrcp'
            case command.output.renderer
            when 'unimrcp'
              Component::MRCPPrompt
            when 'native_or_unimrcp'
              Component::MRCPPrompt
            when 'asterisk'
              Component::MRCPNativePrompt
            else
              raise InvalidCommandError, 'Invalid recognizer/renderer combination'
            end
          else
            Component::ComposedPrompt
          end
        end

        #
        # @return [Hash] AGI result
        #
        # @raises RubyAMI::Error, ChannelGoneError
        def execute_agi_command(command, *params)
          agi = AGICommand.new Punchblock.new_uuid, channel, command, *params
          condition = Celluloid::Condition.new
          register_tmp_handler :ami, name: 'AsyncAGI', [:[], 'SubEvent'] => 'Exec', [:[], 'CommandID'] => agi.id do |event|
            condition.signal event
          end
          agi.execute @ami_client
          event = condition.wait
          return unless event
          agi.parse_result event
        rescue ChannelGoneError, RubyAMI::Error => e
          abort e
        end

        def logger_id
          "#{self.class}: #{id}"
        end

        def redirect_back(other_call = nil)
          redirect_options = {
            'Channel'   => channel,
            'Exten'     => Asterisk::REDIRECT_EXTENSION,
            'Priority'  => Asterisk::REDIRECT_PRIORITY,
            'Context'   => Asterisk::REDIRECT_CONTEXT
          }
          redirect_options.merge!({
            'ExtraChannel' => other_call.channel,
            'ExtraExten'     => Asterisk::REDIRECT_EXTENSION,
            'ExtraPriority'  => Asterisk::REDIRECT_PRIORITY,
            'ExtraContext'   => Asterisk::REDIRECT_CONTEXT
          }) if other_call
          send_ami_action 'Redirect', redirect_options
        end

        def handle_hangup_event(code = 16)
          reason = @hangup_cause || HANGUP_CAUSE_TO_END_REASON[code]
          @block_commands = true
          @components.dup.each_pair do |id, component|
            safe_from_dead_actors do
              component.call_ended if component.alive?
            end
          end
          send_end_event reason, code
        end

        def actor_died(actor, reason)
          if id = @components.key(actor)
            @components.delete id
            return unless reason
            complete_event = Punchblock::Event::Complete.new :component_id => id, :reason => Punchblock::Event::Complete::Error.new
            send_pb_event complete_event
          end
        end

        private

        def fetch_channel_var(variable)
          result = @ami_client.send_action 'GetVar', 'Channel' => channel, 'Variable' => variable
          result['Value'] == '(null)' ? nil : result['Value']
        end

        def send_hangup_command(cause_code = 16)
          send_ami_action 'Hangup', 'Channel' => channel, 'Cause' => cause_code
        end

        def send_ami_action(name, headers = {})
          AMIErrorConverter.convert { @ami_client.send_action name, headers }
        end

        def send_end_event(reason, code = nil)
          send_pb_event Event::End.new(reason: reason, platform_code: code)
          translator.deregister_call id, channel
          terminate
        end

        def execute_component(type, command, options = {})
          type.new_link(command, current_actor).tap do |component|
            register_component component
            component.async.execute
          end
        end

        def send_pb_event(event)
          event.target_call_id = id
          translator.handle_pb_event event
        end

        def offer_event
          Event::Offer.new :to      => agi_env.values_at(:agi_dnid, :agi_extension).detect { |e| e && e != 'unknown' },
                           :from    => "#{agi_env[:agi_calleridname]} <#{[agi_env[:agi_type], agi_env[:agi_callerid]].join('/')}>",
                           :headers => sip_headers
        end

        def sip_headers
          agi_env.to_a.inject({}) do |accumulator, element|
            accumulator['X-' + element[0].to_s] = element[1] || ''
            accumulator
          end
        end

        def variable_for_headers(headers)
          variables = { :punchblock_call_id => id }
          header_counter = 51
          headers.each do |name, value|
            variables["SIPADDHEADER#{header_counter}"] = "\"#{name}: #{value}\""
            header_counter += 1
          end
          variables.inject([]) do |a, (k, v)|
            a << "#{k}=#{v}"
          end.join(',')
        end
      end
    end
  end
end
