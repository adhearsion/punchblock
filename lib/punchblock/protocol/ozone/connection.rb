%w{
  timeout
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  module Protocol
    class Ozone
      class Connection < GenericConnection
        include Blather::DSL

        ##
        # Initialize the required connection attributes
        #
        # @param [Hash] options
        # @option options [String] :username client JID
        # @option options [String] :password XMPP password
        # @option options [Logger] :wire_logger to which all XMPP transactions will be logged
        #
        def initialize(options = {})
          super
          raise ArgumentError unless @username = options.delete(:username)
          raise ArgumentError unless options.has_key? :password
          @client_jid = Blather::JID.new @username

          setup @username, options.delete(:password)

          # This queue is used to synchronize between threads calling #write
          # and the connection-level responses they need to return from the
          # EventMachine loop.
          @result_queues = {}

          @callmap = {} # This hash maps call IDs to their XMPP domain.

          @command_id_to_iq_id = {}
          @iq_id_to_command = {}

          Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)

          # FIXME: Force autoload events so they get registered properly
          [Event::Complete, Event::End, Event::Info, Event::Offer, Ref]
        end

        ##
        # Write a command to the Ozone server for a particular call
        #
        # @param [Call, String] call the call on which to act, or its ID
        # @param [CommandNode] cmd the command to execute on the call
        # @param [String, Optional] command_id the command_id on which to execute
        #
        # @raise Exception if there is a server-side error
        #
        # @return true
        #
        def write(call_id, cmd, command_id = nil)
          cmd.connection = self
          call_id = call_id.call_id if call_id.is_a? Call
          cmd.call_id = call_id
          jid = cmd.is_a?(Command::Dial) ? @client_jid.domain : "#{call_id}@#{@callmap[call_id]}"
          jid << "/#{command_id}" if command_id
          iq = create_iq jid
          @logger.debug "Sending IQ ID #{iq.id} #{cmd.inspect} to #{jid}" if @logger
          iq << cmd
          @iq_id_to_command[iq.id] = cmd
          @result_queues[iq.id] = Queue.new
          write_to_stream iq
          cmd.request!
          result = read_queue_with_timeout @result_queues[iq.id]
          if result.is_a?(Blather::Stanza::Iq)
            ref = result.ozone_node
            cmd.command_id = ref.id if ref.is_a?(Ref)
            cmd.execute!
          end
          @result_queues[iq.id] = nil # Shut down this queue
          raise result if result.is_a? Exception
          true
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
              EM.run { client.run }
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
        # @return [OzoneNode]
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
          @event_queue.push event.is_a?(Event::Offer) ? Punchblock::Call.new(p.call_id, p.to, event.headers_hash) : event
        end

        def handle_iq_result(iq)
          # FIXME: Do we need to raise a warning if the domain changes?
          @callmap[iq.from.node] = iq.from.domain
          # Send this result to the waiting queue
          @logger.debug "Command #{iq.id} completed successfully" if @logger
          ref = iq.ozone_node
          @command_id_to_iq_id[ref.id] = iq.id if ref.is_a?(Ref)
          @result_queues[iq.id].push iq
        end

        def handle_error(iq)
          e = Blather::StanzaError.import iq

          protocol_error = ProtocolError.new e.name, e.text, iq.call_id, iq.command_id

          if @result_queues.has_key?(iq.id)
            @result_queues[iq.id].push protocol_error
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

        def create_iq(jid = nil)
          Blather::Stanza::Iq.new :set, jid || @call_id
        end

        def read_queue_with_timeout(queue, timeout = 3)
          begin
            Timeout::timeout(timeout) { queue.pop }
          rescue Timeout::Error => e
            e.to_s
          end
        end
      end
    end
  end
end
