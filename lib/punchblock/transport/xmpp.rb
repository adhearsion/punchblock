require 'blather/client/dsl'

module Punchblock
  module Transport
    class XMPP
      attr_accessor :event_queue

      include Blather::DSL
      def initialize(protocol, username, password, options)
        setup username, password
        @protocol = protocol
        @event_queue = Queue.new

        Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)
        @logger = options.delete(:transport_logger)


        # Add message handlers
        when_ready { @logger.info "Connected to XMPP as #{username}" }
        iq do |msg|
          pmsg = @protocol::Message.parse msg
          @logger.debug pmsg.inspect
          @event_queue.push pmsg
          write_to_stream msg.reply!
        end
      end

      def send(call, msg)
        @logger.debug "Sending #{msg.to_xml} to #{call.id}"
        iq_stanza = create_iq_stanza(call.id)
        iq_stanza.add_child(msg)
        write_to_stream iq_stanza
      end

      def run
        EM.run { client.run }
      end

      private

      ##
      # Creates the base iq stanza object
      def create_iq_stanza(jid=nil)
        if jid
          iq_stanza = Blather::Stanza::Iq.new(:set, jid)
        else
          iq_stanza = Blather::Stanza::Iq.new(:set, @call_id)
        end
        iq_stanza.from = @client_jid
        iq_stanza
      end

    end
  end
end
