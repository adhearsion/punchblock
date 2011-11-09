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
          component_with_id(command.component_id).execute_command command
        end

        def send_offer
          translator.handle_pb_event! offer_event
        end

        private

        def offer_event
          Event::Offer.new :call_id => id,
                           :to      => agi_env[:agi_dnid],
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
