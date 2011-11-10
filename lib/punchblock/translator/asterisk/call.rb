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
          case ami_event.name
          when 'Hangup'
            send_pb_event Event::End.new(:reason => :hangup)
          when 'AGIExec'
            if component = component_with_id(ami_event['CommandId'])
              component.handle_ami_event! ami_event
            end
          end
        end

        def execute_command(command)
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
            component = Component::Asterisk::AGICommand.new command, current_actor
            register_component component
            component.execute!
          end
        end

        def send_agi_action(command, &block)
          send_ami_action 'AGI', 'Command' => command, 'Channel' => channel, &block
        end

        def send_ami_action(name, headers = {}, &block)
          (name.is_a?(RubyAMI::Action) ? name : RubyAMI::Action.new(name, headers, &block)).tap do |action|
            @current_ami_action = action
            translator.send_ami_action! action
          end
        end

        private

        def send_pb_event(event)
          translator.handle_pb_event! event.tap { |e| e.call_id = id }
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
