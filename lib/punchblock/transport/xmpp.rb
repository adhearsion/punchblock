require 'blather/client/dsl'

module Protocol
  module Transport
    class XMPP
      attr_accessor :event_queue, :command_queue

      include Blather::DSL
      def initialize(username, password, options)
        setup username, password
        @event_queue   = Queue.new
        @command_queue = Queue.new

        Blather.logger  = options.delete(:wire_logger) if options.has_key?(:wire_logger)
        @logger = options.delete(:protocol_logger)


        # Add message handlers
        when_ready { @logger.info "Connected to XMPP as #{username}" }
        iq do |msg|
          #@event_queue.push Message.parse msg
          msg = Message.parse msg
          @logger.debug msg.inspect
          @event_queue.push msg
          # TODO: acknowledge message
        end
      end

      def run
        Thread.new do
          begin
            loop do
              call, msg = @command_queue.pop
              @logger.debug "Sending #{msg.to_xml} to #{call.id}"
              iq_stanza = create_iq_stanza(call.id)
              iq_stanza.add_child(msg)
              write_to_stream iq_stanza
            end
          rescue => e
            @logger.error "Command dequeue crash averted!"
            @logger.error e.message
            @logger.error e.backtrace.join("\n\t")
          end
        end
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
