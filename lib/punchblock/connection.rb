%w{
  timeout
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  class Connection < GenericConnection
    include Blather::DSL

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
      super
      raise ArgumentError unless @username = options.delete(:username)
      raise ArgumentError unless options.has_key? :password
      @rayo_domain = options[:rayo_domain] || Blather::JID.new(@username).domain

      setup @username, options.delete(:password)

      @callmap = {} # This hash maps call IDs to their XMPP domain.

      @component_id_to_iq_id = {}
      @iq_id_to_command = {}

      @auto_reconnect = !!options[:auto_reconnect]
      @reconnect_attempts = 0

      @write_timeout = options[:write_timeout] || 3

      @ping_period = options.has_key?(:ping_period) ? options[:ping_period] : 60

      Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)
    end

    ##
    # Write a command to the Rayo server for a particular call
    #
    # @param [String] call the call ID on which to act
    # @param [CommandNode] cmd the command to execute on the call
    # @param [String, Optional] component_id the component_id on which to execute
    #
    # @raise Exception if there is a server-side error
    #
    # @return true
    #
    def write(call_id, cmd, component_id = nil)
      async_write call_id, cmd, component_id
      cmd.response(@write_timeout).tap { |result| raise result if result.is_a? Exception }
    end

    ##
    # @return [Queue] Pop this queue to determine result of command execution. Will be true or an exception
    def async_write(call_id, cmd, component_id = nil)
      iq = prep_command_for_execution call_id, cmd, component_id
      write_to_stream iq
      cmd.request!
    end

    def prep_command_for_execution(call_id, cmd, component_id = nil)
      cmd.connection = self
      cmd.call_id = call_id
      jid = cmd.is_a?(Command::Dial) ? @rayo_domain : "#{call_id}@#{@callmap[call_id]}"
      jid << "/#{component_id}" if component_id
      create_iq(jid).tap do |iq|
        @logger.debug "Sending IQ ID #{iq.id} #{cmd.inspect} to #{jid}" if @logger
        iq << cmd
        @iq_id_to_command[iq.id] = cmd
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

    ##
    #
    # Get the original command issued by command ID
    #
    # @param [String] component_id
    #
    # @return [RayoNode]
    #
    def original_component_from_id(component_id)
      @iq_id_to_command[@component_id_to_iq_id[component_id]]
    end

    def record_command_id_for_iq_id(command_id, iq_id)
      @component_id_to_iq_id[command_id] = iq_id
    end

    private

    def handle_presence(p)
      throw :pass unless p.rayo_event?
      @logger.info "Receiving event for call ID #{p.call_id}" if @logger
      @callmap[p.call_id] = p.from.domain
      @logger.debug p.inspect if @logger
      event = p.event
      event.connection = self
      if event.source
        event.source.add_event event
      else
        @event_queue.push event
      end
    end

    def handle_iq_result(iq)
      # FIXME: Do we need to raise a warning if the domain changes?
      throw :pass unless command = @iq_id_to_command[iq.id]
      @callmap[iq.from.node] = iq.from.domain
      @logger.debug "Command #{iq.id} completed successfully" if @logger
      command.response = iq
    end

    def handle_error(iq)
      e = Blather::StanzaError.import iq

      protocol_error = ProtocolError.new e.name, e.text, iq.call_id, iq.component_id

      throw :pass unless command = @iq_id_to_command[iq.id]

      command.response = protocol_error
    end

    def register_handlers
      # Push a message to the queue and the log that we connected
      when_ready do
        @event_queue.push connected
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

      # Read/handle call control messages. These are mostly just acknowledgement of commands
      iq :result? do |msg|
        handle_iq_result msg
      end

      # Read/handle error IQs
      iq :error? do |e|
        handle_error e
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
