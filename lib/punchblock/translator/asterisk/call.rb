require 'uri'

module Punchblock
  module Translator
    class Asterisk
      class Call
        include Celluloid

        attr_reader :id, :channel, :translator, :agi_env

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

        def execute_component_command(command)
          component_with_id(command.component_id).execute_command! command
        end

        def send_offer
          send_pb_event offer_event
        end

        def process_ami_event(ami_event)
          pb_logger.trace "Processing AMI event #{ami_event.inspect}"
          case ami_event.name
          when 'Hangup'
            pb_logger.debug "Received a Hangup AMI event. Sending End event."
            send_pb_event Event::End.new(:reason => :hangup)
          when 'AGIExec'
            if component = component_with_id(ami_event['CommandId'])
            pb_logger.debug "Received an AsyncAGI event. Looking for matching AGICommand component."
              pb_logger.debug "Found component #{component.id} for event. Forwarding event..."
              component.handle_ami_event! ami_event
            end
          end
        end

        def execute_command(command)
          pb_logger.debug "Executing command: #{command.inspect}"
          case command
          when Command::Accept
            send_agi_action 'EXEC RINGING' do |response|
              command.response = true
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
            execute_agi_command command
          end
        end

        def send_agi_action(command, &block)
          pb_logger.debug "Sending AGI action #{command}"
          @current_agi_command = Punchblock::Component::Asterisk::AGI::Command.new :name => command, :call_id => id
          @current_agi_command.request!
          @current_agi_command.register_event_handler Punchblock::Event::Complete do |e|
            pb_logger.debug "AGI action received complete event #{e.inspect}"
            block.call e
          end
          execute_agi_command @current_agi_command
        end

        def send_ami_action(name, headers = {}, &block)
          (name.is_a?(RubyAMI::Action) ? name : RubyAMI::Action.new(name, headers, &block)).tap do |action|
            @current_ami_action = action
            pb_logger.debug "Sending AMI action #{action.inspect}"
            translator.send_ami_action! action
          end
        end

        private

        def execute_agi_command(command)
          Component::Asterisk::AGICommand.new(command, current_actor).tap do |component|
            register_component component
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
