%w{
  timeout
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  module Protocol
    class Rayo
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
        #
        def initialize(options = {})
          super
          raise ArgumentError unless @username = options.delete(:username)
          raise ArgumentError unless options.has_key? :password
          @rayo_domain = options[:rayo_domain] || Blather::JID.new(@username).domain

          setup @username, options.delete(:password)

          # This hash is used to synchronize between threads calling #write
          # and the connection-level responses they need to return from the
          # EventMachine loop.
          @command_callbacks = {}

          @callmap = {} # This hash maps call IDs to their XMPP domain.

          @command_id_to_iq_id = {}
          @iq_id_to_command = {}

          @auto_reconnect = !!options[:auto_reconnect]
          @reconnect_attempts = 0

          Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)

          # FIXME: Force autoload events so they get registered properly
          [Event::Answered, Event::Complete, Event::End, Event::Info, Event::Offer, Event::Ringing, Ref]
        end

        ##
        # Write a command to the Rayo server for a particular call
        #
        # @param [String] call the call ID on which to act
        # @param [CommandNode] cmd the command to execute on the call
        # @param [String, Optional] command_id the command_id on which to execute
        #
        # @raise Exception if there is a server-side error
        #
        # @return true
        #
        def write(call_id, cmd, command_id = nil)
          queue = async_write call_id, cmd, command_id
          begin
            Timeout::timeout(3) { queue.pop }
          ensure
            queue = nil # Shut down this queue
          end.tap { |result| raise result if result.is_a? Exception }
        end

        ##
        # @return [Queue] Pop this queue to determine result of command execution. Will be true or an exception
        def async_write(call_id, cmd, command_id = nil)
          iq = prep_command_for_execution call_id, cmd, command_id

          Queue.new.tap do |queue|
            @command_callbacks[iq.id] = lambda do |result|
              case result
              when Blather::Stanza::Iq
                ref = result.rayo_node
                if ref.is_a?(Ref)
                  cmd.command_id = ref.id
                  @command_id_to_iq_id[ref.id] = iq.id
                end
                cmd.execute!
                queue << true
              when Exception
                queue << result
              end
            end

            write_to_stream iq
            cmd.request!
          end
        end

        def prep_command_for_execution(call_id, cmd, command_id = nil)
          cmd.connection = self
          cmd.call_id = call_id
          jid = cmd.is_a?(Command::Dial) ? @rayo_domain : "#{call_id}@#{@callmap[call_id]}"
          jid << "/#{command_id}" if command_id
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
          Thread.new do
            begin
              trap(:INT) do
                @reconnect_attempts = nil
                EM.stop
              end
              trap(:TERM) do
                @reconnect_attempts = nil
                EM.stop
              end
              EM.run { client.run }
            rescue Blather::SASLError, Blather::StreamError => e
              raise ProtocolError.new(e.class.to_s, e.message)
            rescue => e
              puts "Exception in XMPP thread! #{e}"
              puts e.backtrace.join("\t\n")
            end
          end
        end

        def connected?
          client.connected?
        end

        ##
        #
        # Get the original command issued by command ID
        #
        # @param [String] command_id
        #
        # @return [RayoNode]
        #
        def original_command_from_id(command_id)
          @iq_id_to_command[@command_id_to_iq_id[command_id]]
        end

        private

        def handle_presence(p)
          @logger.info "Receiving event for call ID #{p.call_id}" if @logger
          @callmap[p.call_id] = p.from.domain
          @logger.debug p.inspect if @logger
          event = p.event
          event.connection = self
          event.source.add_event event if event.source
          @event_queue.push event
        end

        def handle_iq_result(iq)
          # FIXME: Do we need to raise a warning if the domain changes?
          @callmap[iq.from.node] = iq.from.domain
          @logger.debug "Command #{iq.id} completed successfully" if @logger
          callback = @command_callbacks[iq.id]
          callback.call iq if callback
        end

        def handle_error(iq)
          e = Blather::StanzaError.import iq

          protocol_error = ProtocolError.new e.name, e.text, iq.call_id, iq.command_id

          if callback = @command_callbacks[iq.id]
            callback.call protocol_error
          else
            # Un-associated transport error??
            raise protocol_error
          end
        end

        def register_handlers
          # Push a message to the queue and the log that we connected
          when_ready do
            @event_queue.push connected
            @logger.info "Connected to XMPP as #{@username}" if @logger
            @reconnect_attempts = 0
            @rayo_ping = EM::PeriodicTimer.new(60) { ping_rayo }
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
          presence { |msg| handle_presence msg }
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
end
