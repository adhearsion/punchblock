require 'uri'

module Punchblock
  module Translator
    class Asterisk
      class Call
        include HasGuardedHandlers
        include Celluloid

        attr_reader :id, :channel, :translator, :agi_env, :direction

        HANGUP_CAUSE_TO_END_REASON = Hash.new { :error }
        HANGUP_CAUSE_TO_END_REASON[16] = :hangup
        HANGUP_CAUSE_TO_END_REASON[17] = :busy
        HANGUP_CAUSE_TO_END_REASON[18] = :timeout
        HANGUP_CAUSE_TO_END_REASON[19] = :reject
        HANGUP_CAUSE_TO_END_REASON[21] = :reject
        HANGUP_CAUSE_TO_END_REASON[22] = :reject
        HANGUP_CAUSE_TO_END_REASON[102] = :timeout

        def initialize(channel, translator, agi_env = '')
          @channel, @translator = channel, translator
          @agi_env = parse_environment agi_env
          @id, @components = UUIDTools::UUID.random_create.to_s, {}
          pb_logger.debug "Starting up call with channel #{channel}, id #{@id}"
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
          "#<#{self.class}:#{id} Channel: #{channel.inspect}>"
        end

        def dial(dial_command)
          @direction = :outbound
          originate_action = Punchblock::Component::Asterisk::AMI::Action.new :name => 'Originate',
                                                                              :params => {
                                                                                :async       => true,
                                                                                :application => 'AGI',
                                                                                :data        => 'agi:async',
                                                                                :channel     => dial_command.to,
                                                                                :callerid    => dial_command.from,
                                                                                :variable    => "punchblock_call_id=#{id}"
                                                                              }
          originate_action.request!
          translator.execute_global_command! originate_action
          dial_command.response = Ref.new :id => id
        end

        def outbound?
          direction == :outbound
        end

        def inbound?
          direction == :inbound
        end

        def channel=(other)
          pb_logger.info "Channel is changing from #{channel} to #{other}."
          @channel = other
        end

        def process_ami_event(ami_event)
          pb_logger.trace "Processing AMI event #{ami_event.inspect}"
          case ami_event.name
          when 'Hangup'
            pb_logger.debug "Received a Hangup AMI event. Sending End event."
            send_end_event HANGUP_CAUSE_TO_END_REASON[ami_event['Cause'].to_i]
          when 'AsyncAGI'
            pb_logger.debug "Received an AsyncAGI event. Looking for matching AGICommand component."
            if component = component_with_id(ami_event['CommandID'])
              pb_logger.debug "Found component #{component.id} for event. Forwarding event..."
              component.handle_ami_event! ami_event
            else
              pb_logger.debug "Could not find component for AMI event: #{ami_event}"
            end
          when 'Newstate'
            pb_logger.debug "Received a Newstate AMI event with state #{ami_event['ChannelState']}: #{ami_event['ChannelStateDesc']}"
            case ami_event['ChannelState']
            when '5'
              send_pb_event Event::Ringing.new
            when '6'
              send_pb_event Event::Answered.new
            end
          end
          trigger_handler :ami, ami_event
        end

        def execute_command(command)
          pb_logger.debug "Executing command: #{command.inspect}"
          if command.component_id
            if component = component_with_id(command.component_id)
              component.execute_command! command
            else
              command.response = ProtocolError.new 'component-not-found', "Could not find a component with ID #{command.component_id} for call #{id}", id, command.component_id
            end
          end
          case command
          when Command::Accept
            if outbound?
              pb_logger.trace "Attempting to accept an outbound call. Skipping RINGING."
              command.response = true
            else
              pb_logger.trace "Attempting to accept an inbound call. Executing RINGING."
              send_agi_action 'EXEC RINGING' do |response|
                command.response = true
              end
            end
          when Command::Answer
            send_agi_action 'EXEC ANSWER' do |response|
              command.response = true
            end
          when Command::Hangup
            send_ami_action 'Hangup', 'Channel' => channel do |response|
              command.response = true
            end
          when Punchblock::Component::Asterisk::AGI::Command
            execute_component Component::Asterisk::AGICommand, command
          when Punchblock::Component::Output
            execute_component Component::Output, command
          when Punchblock::Component::Input
            execute_component Component::Input, command
          else
            command.response = ProtocolError.new 'command-not-acceptable', "Did not understand command for call #{id}", id
          end
        end

        def send_agi_action(command, *params, &block)
          pb_logger.debug "Sending AGI action #{command}"
          @current_agi_command = Punchblock::Component::Asterisk::AGI::Command.new :name => command, :params => params, :call_id => id
          @current_agi_command.request!
          @current_agi_command.register_handler :internal, Punchblock::Event::Complete do |e|
            pb_logger.debug "AGI action received complete event #{e.inspect}"
            block.call e
          end
          execute_component Component::Asterisk::AGICommand, @current_agi_command, :internal => true
        end

        def send_ami_action(name, headers = {}, &block)
          (name.is_a?(RubyAMI::Action) ? name : RubyAMI::Action.new(name, headers, &block)).tap do |action|
            @current_ami_action = action
            pb_logger.debug "Sending AMI action #{action.inspect}"
            translator.send_ami_action! action
          end
        end

        def logger_id
          "#{self.class}: #{id}"
        end

        private

        def send_end_event(reason)
          send_pb_event Event::End.new(:reason => reason)
          current_actor.terminate!
        end

        def execute_component(type, command, options = {})
          type.new(command, current_actor).tap do |component|
            register_component component
            component.internal = true if options[:internal]
            component.execute!
          end
        end

        def send_pb_event(event)
          event.call_id = id
          pb_logger.debug "Sending Punchblock event: #{event.inspect}"
          translator.handle_pb_event! event
        end

        def offer_event
          Event::Offer.new :to      => agi_env[:agi_dnid],
                           :from    => [agi_env[:agi_type].downcase, agi_env[:agi_callerid]].join(':'),
                           :headers => sip_headers
        end

        def sip_headers
          agi_env.to_a.inject({}) do |accumulator, element|
            accumulator[('x_' + element[0].to_s).to_sym] = element[1] || ''
            accumulator
          end
        end

        def parse_environment(agi_env)
          agi_env_as_array(agi_env).inject({}) do |accumulator, element|
            accumulator[element[0].to_sym] = element[1] || ''
            accumulator
          end
        end

        def agi_env_as_array(agi_env)
          URI.unescape(agi_env).encode.split("\n").map { |p| p.split ': ' }
        end
      end
    end
  end
end
