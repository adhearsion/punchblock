%w{
  timeout
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  module Connection
    class XMPP
      include Blather::DSL
      attr_accessor :event_handler

      ##
      # Initialize the required connection attributes
      #
      # @param [Hash] options
      # @option options [String] :username client JID
      # @option options [String] :password XMPP password
      # @option options [String] :rayo_domain the domain on which Rayo is running
      # @option options [Logger] :wire_logger to which all XMPP transactions will be logged
      # @option options [Boolean, Optional] :auto_reconnect whether or not to auto reconnect
      # @option options [Numeric, Optional] :write_timeout for which to wait on a command response
      # @option options [Numeric, nil, Optional] :ping_period interval in seconds on which to ping the server. Nil or false to disable
      #
      def initialize(options = {})
        raise ArgumentError unless (@username = options[:username]) && options[:password]

        setup *[:username, :password, :host, :port, :certs].map { |key| options.delete key }

        @rayo_domain = options[:rayo_domain] || Blather::JID.new(@username).domain

        @callmap = {} # This hash maps call IDs to their XMPP domain.

        @auto_reconnect = !!options[:auto_reconnect]
        @reconnect_attempts = 0

        @ping_period = options.has_key?(:ping_period) ? options[:ping_period] : 60

        @event_handler = lambda { |event| raise 'No event handler set' }

        Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)
      end

      def write(command, options = {})
        iq = prep_command_for_execution command, options
        client.write_with_handler iq do |response|
          if response.result?
            handle_iq_result response, command
          elsif response.error?
            handle_error response, command
          end
        end
        command.request!
      end

      def prep_command_for_execution(command, options = {})
        call_id, component_id = options.values_at :call_id, :component_id
        command.connection = self
        command.call_id = call_id
        jid = command.is_a?(Command::Dial) ? @rayo_domain : "#{call_id}@#{@callmap[call_id]}"
        jid << "/#{component_id}" if component_id
        create_iq(jid).tap do |iq|
          @logger.debug "Sending IQ ID #{iq.id} #{command.inspect} to #{jid}" if @logger
          iq << command
        end
      end

      ##
      # Fire up the connection
      #
      def run
        register_handlers
        connect
      end

      def connect
        begin
          EM.run { client.run }
        rescue Blather::SASLError, Blather::StreamError => e
          raise ProtocolError.new(e.class.to_s, e.message)
        end
      end

      def stop
        @reconnect_attempts = nil
        client.close
      end

      def connected?
        client.connected?
      end

      private

      def handle_presence(p)
        throw :pass unless p.rayo_event? && p.from.domain == @rayo_domain
        @logger.info "Receiving event for call ID #{p.call_id}" if @logger
        @callmap[p.call_id] = p.from.domain
        @logger.debug p.inspect if @logger
        event = p.event
        event.connection = self
        event_handler.call event
      end

      def handle_iq_result(iq, command)
        # FIXME: Do we need to raise a warning if the domain changes?
        @callmap[iq.from.node] = iq.from.domain
        @logger.debug "Command #{iq.id} completed successfully" if @logger
        command.response = iq.rayo_node.is_a?(Ref) ? iq.rayo_node : true
      end

      def handle_error(iq, command = nil)
        e = Blather::StanzaError.import iq
        protocol_error = ProtocolError.new e.name, e.text, iq.call_id, iq.component_id
        command.response = protocol_error if command
      end

      def register_handlers
        # Push a message to the queue and the log that we connected
        when_ready do
          event_handler.call Connected.new
          @logger.info "Connected to XMPP as #{@username}" if @logger
          @reconnect_attempts = 0
          @rayo_ping = EM::PeriodicTimer.new(@ping_period) { ping_rayo } if @ping_period
        end

        disconnected do
          @rayo_ping.cancel if @rayo_ping
          if @auto_reconnect && @reconnect_attempts
            timer = 30 * 2 ** @reconnect_attempts
            @logger.warn "XMPP disconnected. Tried to reconnect #{@reconnect_attempts} times. Reconnecting in #{timer}s." if @logger
            sleep timer
            @logger.info "Trying to reconnect..." if @logger
            @reconnect_attempts += 1
            connect
          end
        end

        # Read/handle presence requests. This is how we get events.
        presence do |msg|
          handle_presence msg
        end
      end

      def ping_rayo
        client.write_with_handler Blather::Stanza::Iq::Ping.new(:set, @rayo_domain) do |response|
          begin
            handle_error response if response.is_a? Blather::BlatherError
          rescue ProtocolError => e
            raise e unless e.name == :feature_not_implemented
          end
        end
      end

      def create_iq(jid = nil)
        Blather::Stanza::Iq.new :set, jid || @call_id
      end
    end
  end
end
