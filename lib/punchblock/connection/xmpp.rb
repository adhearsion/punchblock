# encoding: utf-8

%w{
  timeout
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  module Connection
    class XMPP < GenericConnection
      include Blather::DSL
      attr_accessor :event_handler, :root_domain

      ##
      # Initialize the required connection attributes
      #
      # @param [Hash] options
      # @option options [String] :username client JID
      # @option options [String] :password XMPP password
      # @option options [String] :rayo_domain the domain on which Rayo is running
      # @option options [Numeric, Optional] :write_timeout for which to wait on a command response
      # @option options [Numeric, Optional] :connection_timeout for which to wait on a connection being established
      # @option options [Numeric, nil, Optional] :ping_period interval in seconds on which to ping the server. Nil or false to disable
      #
      def initialize(options = {})
        raise ArgumentError unless (@username = options[:username]) && options[:password]

        setup(*[:username, :password, :host, :port, :certs, :connection_timeout].map { |key| options.delete key })

        @root_domain = Blather::JID.new(options[:root_domain] || options[:rayo_domain] || @username).domain

        @joined_mixers = []

        @ping_period = options.has_key?(:ping_period) ? options[:ping_period] : 60

        Blather.logger = pb_logger
        Blather.default_log_level = :trace if Blather.respond_to? :default_log_level

        register_handlers

        super()
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
        command.connection    = self
        command.target_call_id    ||= options[:call_id]
        command.target_mixer_name ||= options[:mixer_name]
        command.domain            ||= options[:domain]
        command.component_id      ||= options[:component_id]
        if command.is_a?(Command::Join) && command.mixer_name
          @joined_mixers << command.mixer_name
        end
        create_iq(jid_for_command(command)).tap do |iq|
          command.to_rayo(iq)
        end
      end

      ##
      # Fire up the connection
      #
      def run
        connect
      end

      def connect
        begin
          EM.run { client.run }
        rescue Blather::Stream::ConnectionFailed, Blather::Stream::ConnectionTimeout, Blather::StreamError => e
          raise DisconnectedError.new(e.class.to_s, e.message)
        end
      end

      def stop
        client.close if client.connected?
      end

      def connected?
        client.connected?
      end

      def ready!
        send_presence :chat
        super
      end

      def not_ready!
        send_presence :dnd
        super
      end

      private

      def jid_for_command(command)
        return root_domain if command.is_a?(Command::Dial)

        if command.target_call_id
          node = command.target_call_id
        elsif command.target_mixer_name
          node = command.target_mixer_name
        end

        Blather::JID.new(node, command.domain || root_domain, command.component_id).to_s
      end

      def send_presence(presence)
        status = Blather::Stanza::Presence::Status.new presence
        status.to = root_domain
        client.write status
      end

      def handle_presence(p)
        throw :pass unless p.rayo_event?
        event = p.event
        event.connection = self
        event.domain = p.from.domain
        event.transport = "xmpp"
        if @joined_mixers.include?(p.call_id)
          event.target_mixer_name = p.call_id
        else
          event.target_call_id = p.call_id
        end
        event_handler.call event
      end

      def handle_iq_result(iq, command)
        command.response = iq.rayo_node.is_a?(Ref) ? iq.rayo_node : true
      end

      def handle_error(iq, command = nil)
        e = Blather::StanzaError.import iq
        protocol_error = ProtocolError.new.setup e.name, e.text, iq.call_id, iq.component_id
        command.response = protocol_error if command
      end

      def register_handlers
        # Push a message to the queue and the log that we connected
        when_ready do
          event_handler.call Connected.new
          pb_logger.info "Connected to XMPP as #{@username}"
          @rayo_ping = EM::PeriodicTimer.new(@ping_period) { ping_rayo } if @ping_period
          throw :pass
        end

        disconnected do
          @rayo_ping.cancel if @rayo_ping
          raise DisconnectedError
        end

        # Read/handle presence requests. This is how we get events.
        presence do |msg|
          handle_presence msg
        end
      end

      def ping_rayo
        client.write_with_handler Blather::Stanza::Iq::Ping.new(:get, root_domain) do |response|
          begin
            handle_error response if response.is_a? Blather::BlatherError
          rescue ProtocolError => e
            raise unless e.name == :feature_not_implemented
          end
        end
      end

      def create_iq(jid = nil)
        Blather::Stanza::Iq.new :set, jid || @call_id
      end
    end
  end
end
