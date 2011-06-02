require 'timeout'
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
        @client_jid = Blather::JID.new @username

        setup @username, options.delete(:password)

        # This queue is used to synchronize between threads calling #write
        # and the transport-level responses they need to return from the
        # EventMachine loop.
        @result_queues = {}

        # This hash maps call IDs to their XMPP domain.
        @callmap = {}

        Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)

        # Push a message to the queue and the log that we connected
        when_ready {
          @event_queue.push Protocol::GenericProtocol::connected
          @logger.info "Connected to XMPP as #{@username}" if @logger
        }

        iq do |msg|
          read msg
        end
      end

      def read(msg)
        jid = Blather::JID.new msg['from']
        call_id = jid.node
        # FIXME: Do we need to raise a warning if the domain changes?
        @callmap[call_id] = jid.domain
        command_id = jid.resource
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
          if @result_queues.has_key?(msg['id'])
            @result_queues[msg['id']].push TransportError.new msg
          else
            # Un-associated transport error??
            raise TransportError.new msg
          end
        else
          raise TransportError, msg
        end
      end

      def write(call, msg)
        # The interface between the Protocol layer and the Transport layer is
        # defined to be a String.  Because Blather uses Nokogiri to construct
        # and send XMPP messages, we need to convert the Protocol layer to a
        # Nokogiri object, if it contains XML (ie. Ozone).
        # FIXME: What happens if Nokogiri tries to parse non-XML string?
        if msg.class == Punchblock::Protocol::Ozone::Dial
          iq = create_iq @client_jid.domain
          @logger.debug "Sending Command ID #{iq['id']} #{msg.to_xml} to #{@client_jid.domain}" if @logger
        else
          iq = create_iq "#{call.call_id}@#{@callmap[call.call_id]}"
          @logger.debug "Sending Command ID #{iq['id']} #{msg.to_xml} to #{call.call_id}" if @logger
        end
        msg = Nokogiri::XML::Node.new('', Nokogiri::XML::Document.new).parse(msg.to_s)
        @result_queues[iq['id']] = Queue.new
        iq.add_child msg
        write_to_stream iq
        result = read_queue_with_timeout @result_queues[iq['id']]
        # Shut down this queue
        @result_queues[iq['id']] = nil
        # FIXME: Error handling
        raise result if result.is_a? Exception
        true
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

      def read_queue_with_timeout(queue, timeout=3)
        begin
          data = Timeout::timeout(timeout) {
            queue.pop
          }
        rescue Timeout::Error => e
          data = e.to_s
        end
        data
      end
    end
  end
end
