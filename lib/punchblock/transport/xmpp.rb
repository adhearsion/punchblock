require 'blather/client/dsl'
require 'punchblock/transport/generic_transport'
require 'punchblock/protocol/generic_protocol'

module Punchblock
  module Transport
    ##
    # This exception may be raised if a transport error is detected.
    class TransportError < StandardError; end

    class XMPP < GenericTransport
      attr_accessor :event_queue

      include Blather::DSL
      def initialize(protocol, options)
        super
        raise ArgumentError unless @username = options.delete(:username)
        raise ArgumentError unless options.has_key? :password
        setup @username, options.delete(:password)

        # This queue is used to synchronize between threads calling #write
        # and the transport-level responses they need to return from the
        # EventMachine loop.
        @result_queues = {}

        Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)
        
        # Push a message to the queue and the log that we connected
        when_ready { 
          @event_queue.push Protocol::GenericProtocol::connected
          @logger.info "Connected to XMPP as #{@username}" if @logger
        }

        iq do |msg|
          jid = Blather::JID.new msg['from']
          call_id = "#{jid.node}@#{jid.domain}"
          command_id = "#{jid.resource}"
          case msg['type']
          when 'set'
            pmsg = @protocol::Message.parse call_id, command_id, msg.children.first.to_xml
            @logger.debug pmsg.inspect if @logger
            @event_queue.push pmsg
            write_to_stream msg.reply!
          when 'result'
            # Send this result to the waiting queue
            @logger.debug "Command #{msg['id']} completed successfully" if @logger
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
            # FIXME: This should probably be parsed by the Protocol layer and return
            # a ProtocolError exception.
            raise TransportError, msg
          else
            raise TransportError, msg
          end
        end
      end

      def write(call, msg)
        # The interface between the Protocol layer and the Transport layer is
        # defined to be a String.  Because Blather uses Nokogiri to construct
        # and send XMPP messages, we need to convert the Protocol layer to a
        # Nokogiri object, if it contains XML (ie. Ozone).
        # FIXME: What happens if Nokogiri tries to parse non-XML string?
        msg = Nokogiri::XML::Node.new('', Nokogiri::XML::Document.new).parse(msg.to_s)
        iq = create_iq call.id
        @logger.debug "Sending Command ID #{iq['id']} #{msg.to_xml} to #{call.id}" if @logger
        @result_queues[iq['id']] = Queue.new
        iq.add_child msg
        write_to_stream iq
        # Block until we get a response to this message
        # TODO: Implement a timeout
        result = @result_queues[iq['id']].pop
        # Shut down this queue
        @result_queues[iq['id']] = nil
        # FIXME: Error handling
        result['jid']
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
