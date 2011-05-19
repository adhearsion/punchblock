require 'blather/client/dsl'

module Ozone
  module Protocol
    class XMPP
      include Blather::DSL
      def initialize(username, password)
        setup username, password

        # Add message handlers
        when_ready { puts "Connected to XMPP as #{username}" }
        iq { |msg| process_iq msg }
      end

      def process_iq(msg)
        puts msg.inspect
        return true

#############
        msg_data = msg.to_hash
        case msg_data['iq']['type']
        when 'set'
          @ozone.set_context self, msg, msg_data
          @ozone.accept
          case msg.children[0].name
          when 'offer'
            @logger.ap 'Waiting for your input on the *offer*->>'
          when 'complete'
            @ozone.state[:complete] = true
            @ozone.state[:ref] = nil
            @logger.ap "Waiting for you input after issuing a #{@ozone.state[:status].to_s}->>"
          when 'info'
            @logger.ap "Waiting for you input after issuing a *#{msg.children[0].children[0].name}->>"
          when 'end'
            if msg.children[0].children[0].name != 'error'
              @ozone.reset_state
              @logger.ap "+++++Call Ended #{msg.from}++++"
            end
          end
        when 'result'
          if msg.children[0]
            case msg.children[0].name
            when 'ref'
              @ozone.state[:ref] = msg.children[0].attributes['jid'].value
            end
          end
        when 'error'
          @logger.warn "Protocol error: #{msg.inspect}"
        end
      end

      def run
        EM.run { client.run }
      end
    end
  end
end
