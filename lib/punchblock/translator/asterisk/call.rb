# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      class Call
        include HasGuardedHandlers
        include Celluloid
        include DeadActorSafety

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

        def initialize(channel, translator, agi_env = nil)
          @channel, @translator = channel, translator
          @agi_env = agi_env || {}
          @id, @components = Punchblock.new_uuid, {}
          @answered = false
          @pending_joins = {}
          @progress_sent = false
          @block_commands = false
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

        def send_progress
          return if answered? || outbound? || @progress_sent
          @progress_sent = true
          send_agi_action "EXEC Progress"
        end

        def channel=(other)
          @channel = other
        end

        def process_ami_event(ami_event)
          send_pb_event Event::Asterisk::AMI::Event.new(:name => ami_event.name, :attributes => ami_event.headers)

          case ami_event.name
          when 'Hangup'
            @block_commands = true
            @components.dup.each_pair do |id, component|
              safe_from_dead_actors do
                component.call_ended if component.alive?
              end
            end
            send_end_event HANGUP_CAUSE_TO_END_REASON[ami_event['Cause'].to_i]
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
            join_command   = @pending_joins[ami_event['Channel1']]
            join_command ||= @pending_joins[ami_event['Channel2']]
            join_command.response = true if join_command
          when 'Bridge'
            other_call_channel = ([ami_event['Channel1'], ami_event['Channel2']] - [channel]).first
            if other_call = translator.call_for_channel(other_call_channel)
              event = case ami_event['Bridgestate']
              when 'Link'
                Event::Joined.new.tap do |e|
                  e.call_id = other_call.id
                end
              when 'Unlink'
                Event::Unjoined.new.tap do |e|
                  e.call_id = other_call.id
                end
              end
              send_pb_event event
            end
          when 'Unlink'
            other_call_channel = ([ami_event['Channel1'], ami_event['Channel2']] - [channel]).first
            if other_call = translator.call_for_channel(other_call_channel)
              event = Event::Unjoined.new.tap do |e|
                e.call_id = other_call.id
              end
              send_pb_event event
            end
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
              send_agi_action 'EXEC RINGING' do |response|
                command.response = true
              end
            end
          when Command::Answer
            send_agi_action 'ANSWER' do |response|
              command.response = true
            end
          when Command::Hangup
            send_ami_action 'Hangup', 'Channel' => channel, 'Cause' => 16 do |response|
              command.response = true
            end
          when Command::Join
            other_call = translator.call_with_id command.call_id
            @pending_joins[other_call.channel] = command
            send_agi_action 'EXEC Bridge', other_call.channel
          when Command::Unjoin
            other_call = translator.call_with_id command.call_id
            redirect_back other_call do |response|
              case response
              when RubyAMI::Error
                command.response = ProtocolError.new.setup 'error', response.message
              else
                command.response = true
              end
            end
          when Command::Reject
            rejection = case command.reason
            when :busy
              'EXEC Busy'
            when :decline
              'EXEC Busy'
            when :error
              'EXEC Congestion'
            else
              'EXEC Congestion'
            end
            send_agi_action rejection do |response|
              command.response = true
            end
          when Punchblock::Component::Asterisk::AGI::Command
            execute_component Component::Asterisk::AGICommand, command
          when Punchblock::Component::Output
            execute_component Component::Output, command
          when Punchblock::Component::Input
            execute_component Component::Input, command
          when Punchblock::Component::Record
            execute_component Component::Record, command
          else
            command.response = ProtocolError.new.setup 'command-not-acceptable', "Did not understand command for call #{id}", id
          end
        rescue Celluloid::DeadActorError
          command.response = ProtocolError.new.setup :item_not_found, "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
        end

        def send_agi_action(command, *params, &block)
          @current_agi_command = Punchblock::Component::Asterisk::AGI::Command.new :name => command, :params => params, :target_call_id => id
          @current_agi_command.request!
          @current_agi_command.register_handler :internal, Punchblock::Event::Complete do |e|
            block.call e if block
          end
          execute_component Component::Asterisk::AGICommand, @current_agi_command, :internal => true
        end

        def send_ami_action(name, headers = {}, &block)
          (name.is_a?(RubyAMI::Action) ? name : RubyAMI::Action.new(name, headers, &block)).tap do |action|
            @current_ami_action = action
            translator.send_ami_action action
          end
        end

        def logger_id
          "#{self.class}: #{id}"
        end

        def redirect_back(other_call = nil, &block)
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
          send_ami_action 'Redirect', redirect_options, &block
        end

        def actor_died(actor, reason)
          return unless reason
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
          after(5) { shutdown }
        end

        def execute_component(type, command, options = {})
          type.new_link(command, current_actor).tap do |component|
            register_component component
            component.internal = true if options[:internal]
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
            accumulator[('x_' + element[0].to_s).to_sym] = element[1] || ''
            accumulator
          end
        end

        def variable_for_headers(headers)
          variables = { :punchblock_call_id => id }
          header_counter = 51
          headers.each do |header|
            variables["SIPADDHEADER#{header_counter}"] = "\"#{header.name}: #{header.value}\""
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
