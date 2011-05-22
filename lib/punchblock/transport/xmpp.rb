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
        @result_queues = {}

        Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)
        @logger = options.delete(:transport_logger)

        # Add message handlers
        when_ready { @logger.info "Connected to XMPP as #{username}" }

        iq do |msg|
          jid = Blather::JID.new msg['from']
          call_id = "#{jid.node}@#{jid.domain}"
          command_id = "#{jid.resource}"
          case msg['type']
          when 'set'
            pmsg = @protocol::Message.parse call_id, command_id, msg.children
            @logger.debug pmsg.inspect
            @event_queue.push pmsg
            write_to_stream msg.reply!
          when 'result'
            # Send this result to the waiting queue
            @result_queues[msg['id']].push msg
          when 'error'
            # TODO: Example messages to handle:
            #------
            #<iq type="error" id="blather0016" to="usera@127.0.0.1/voxeo" from="15dce14a-778e-42f2-9ac4-501805ec0388@127.0.0.1">
            #  <answer xmlns="urn:xmpp:ozone:1"/>
            #  <error type="cancel">
            #    <item-not-found xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
            #  </error>
            #</iq>
            #------
            raise ProtocolError, msg
          else
            raise ProtocolError, msg
          end
        end
      end

      def send(call, msg)
        @logger.debug "Sending #{msg.to_xml} to #{call.id}"
        iq = create_iq call.id
        @result_queues[iq['id']] = Queue.new
        iq.add_child msg
        write_to_stream iq
        # Block until we get a response to this message
        # TODO: Implement a timeout
        result = @result_queues[iq['id']].pop
        # Shut down this queue
        @result_queues[iq['id']] = nil
        # FIXME: Error handling
        return result['jid']
      end

      def run
        EM.run { client.run }
      end

      private

      ##
      # Creates the base iq stanza object
      def create_iq(jid = nil)
        iq_stanza = Blather::Stanza::Iq.new :set, jid || @call_id
        iq_stanza.from = @client_jid
        iq_stanza
      end

    end
  end
end
