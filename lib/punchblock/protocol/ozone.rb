%w{
nokogiri
timeout
blather/client/dsl
punchblock/protocol/generic_connection
}.each { |f| require f }

module Punchblock
  module Protocol
    module Ozone

      BASE_OZONE_NAMESPACE  = 'urn:xmpp:ozone'
      OZONE_VERSION         = '1'
      OZONE_NAMESPACES      = {:core => [BASE_OZONE_NAMESPACE, OZONE_VERSION].compact.join(':')}

      [:ext, :transfer, :say, :ask, :conference].each do |ns|
        OZONE_NAMESPACES[ns] = [BASE_OZONE_NAMESPACE, ns.to_s, OZONE_VERSION].compact.join(':')
      end

      class Presence < ::Blather::Stanza::Presence
        register :ozone_event, nil, OZONE_NAMESPACES[:core]

        def event
          Event.import children.first, :call_id => call_id, :command_id => command_id
        end

        def call_id
          from.node
        end

        def command_id
          from.resource
        end
      end

      # TODO: Remove as much of the duplication of Blather::XMPPNode as possible here
      class OzoneNode < Nokogiri::XML::Node
        @@registrations = {}

        class_inheritable_accessor :registered_ns, :registered_name

        attr_accessor :call_id, :command_id

        # Register a new stanza class to a name and/or namespace
        #
        # This registers a namespace that is used when looking
        # up the class name of the object to instantiate when a new
        # stanza is received
        #
        # @param [#to_s] name the name of the node
        # @param [String, nil] ns the namespace the node belongs to
        def self.register(name, ns = nil)
          self.registered_name = name.to_s
          self.registered_ns = ns.is_a?(Symbol) ? OZONE_NAMESPACES[ns] : ns
          @@registrations[[self.registered_name, self.registered_ns]] = self
        end

        # Find the class to use given the name and namespace of a stanza
        #
        # @param [#to_s] name the name to lookup
        # @param [String, nil] xmlns the namespace the node belongs to
        # @return [Class, nil] the class appropriate for the name/ns combination
        def self.class_from_registration(name, ns = nil)
          @@registrations[[name.to_s, ns]]
        end

        # Import an XML::Node to the appropriate class
        #
        # Looks up the class the node should be then creates it based on the
        # elements of the XML::Node
        # @param [XML::Node] node the node to import
        # @return the appropriate object based on the node name and namespace
        def self.import(node, call_id = nil, command_id = nil)
          ns = (node.namespace.href if node.namespace)
          klass = class_from_registration(node.element_name, ns)
          event = if klass && klass != self
            klass.import node
          else
            new(node.element_name).inherit node
          end
          event.tap do |event|
            event.call_id = call_id
            event.command_id = command_id
          end
        end

        # Create a new Node object
        #
        # @param [String, nil] name the element name
        # @param [XML::Document, nil] doc the document to attach the node to. If
        # not provided one will be created
        # @return a new object with the registered name and namespace
        def self.new(name = nil, doc = nil)
          name ||= self.registered_name

          node = super name.to_s, (doc || Nokogiri::XML::Document.new)
          node.document.root = node unless doc
          node.namespace = self.registered_ns
          node
        end

        # Helper method to read an attribute
        #
        # @param [#to_sym] attr_name the name of the attribute
        # @param [String, Symbol, nil] to_call the name of the method to call on
        # the returned value
        # @return nil or the value
        def read_attr(attr_name, to_call = nil)
          val = self[attr_name.to_sym]
          val && to_call ? val.__send__(to_call) : val
        end

        # Helper method to write a value to an attribute
        #
        # @param [#to_sym] attr_name the name of the attribute
        # @param [#to_s] value the value to set the attribute to
        def write_attr(attr_name, value)
          self[attr_name.to_sym] = value
        end

        # Helper method to read the content of a node
        #
        # @param [#to_sym] node the name of the node
        # @param [String, Symbol, nil] to_call the name of the method to call on
        # the returned value
        # @return nil or the value
        def read_content(node, to_call = nil)
          val = content_from node.to_sym
          val && to_call ? val.__send__(to_call) : val
        end

        # Inherit the attributes and children of an XML::Node
        #
        # @param [XML::Node] stanza the node to inherit
        # @return [self]
        def inherit(node)
          set_namespace node.namespace if node.namespace
          inherit_attrs node.attributes
          node.children.each do |c|
            self << (n = c.dup)
            ns = n.namespace_definitions.find { |ns| ns.prefix == c.namespace.prefix }
            n.namespace = ns if ns
          end
          self
        end

        # Inherit a set of attributes
        #
        # @param [Hash] attrs a hash of attributes to set on the node
        # @return [self]
        def inherit_attrs(attrs)
          attrs.each  { |name, value| self[name] = value }
          self
        end

        # @private
        alias_method :nokogiri_namespace=, :namespace=
        # Attach a namespace to the node
        #
        # @overload namespace=(ns)
        #   Attach an already created XML::Namespace
        #   @param [XML::Namespace] ns the namespace object
        # @overload namespace=(ns)
        #   Create a new namespace and attach it
        #   @param [String] ns the namespace uri
        # @overload namespace=(namespaces)
        #   Createa and add new namespaces from a hash
        #   @param [Hash] namespaces a hash of prefix => uri pairs
        def namespace=(namespaces)
          case namespaces
          when Nokogiri::XML::Namespace
            self.nokogiri_namespace = namespaces
          when String
            self.add_namespace nil, namespaces
          when Hash
            if ns = namespaces.delete(nil)
              self.add_namespace nil, ns
            end
            namespaces.each do |p, n|
              ns = self.add_namespace p, n
              self.nokogiri_namespace = ns
            end
          end
        end

        # Helper method to get the node's namespace
        #
        # @return [XML::Namespace, nil] The node's namespace object if it exists
        def namespace_href
          namespace.href if namespace
        end

        # The node as XML
        #
        # @return [String] XML representation of the node
        def inspect
          self.to_xml
        end

        # Check that a set of fields are equal between nodes
        #
        # @param [XMPPNode] other the other node to compare against
        # @param [*#to_s] fields the set of fields to compare
        # @return [Fixnum<-1,0,1>]
        def eql?(o, *fields)
          o.is_a?(self.class) && fields.all? { |f| self.__send__(f) == o.__send__(f) }
        end

        # @private
        def ==(o)
          eql?(o)
        end
      end

      # TODO: Figure out if we need this
      class Event < OzoneNode

      end

      class Command < OzoneNode

      end

      module HasHeaders
        def headers_hash
          headers.inject({}) do |hash, header|
            hash[header.name] = header.value
            hash
          end
        end

        def headers
          find('//ns:header', :ns => self.class.registered_ns).map do |i|
            Header.new i
          end
        end

        def headers=(headers)
          find('//ns:header', :ns => self.class.registered_ns).each &:remove
          if headers.is_a? Hash
            headers.each_pair { |k,v| self << Header.new(k, v) }
          elsif headers.is_a? Array
            [headers].flatten.each { |i| self << Header.new(i) }
          end
        end
      end

      class Connection < GenericConnection
        attr_accessor :event_queue

        include Blather::DSL
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

          Blather.logger = options.delete(:wire_logger) if options.has_key?(:wire_logger)

          # Push a message to the queue and the log that we connected
          when_ready {
            @event_queue.push connected
            @logger.info "Connected to XMPP as #{@username}" if @logger
          }

          iq { |msg| read msg }

          presence do |msg|
            @logger.debug msg.inspect if @logger
            event = msg.event
            @event_queue.push event.is_a?(Offer) ? Punchblock::Call.new(event.call_id, msg.to, event.headers_hash) : event
          end
        end

        def read(iq)
          # FIXME: Do we need to raise a warning if the domain changes?
          @callmap[iq.from.node] = iq.from.domain
          case iq.type
          when :result
            # Send this result to the waiting queue
            @logger.debug "Command #{iq.id} completed successfully" if @logger
            @result_queues[iq.id].push iq
          when :error
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
            if @result_queues.has_key?(iq.id)
              @result_queues[iq.id].push TransportError.new iq
            else
              # Un-associated transport error??
              raise TransportError.new iq
            end
          else
            raise TransportError, iq
          end
        end

        def write(call, msg)
          # The interface between the Protocol layer and the Transport layer is
          # defined to be a String.  Because Blather uses Nokogiri to construct
          # and send XMPP messages, we need to convert the Protocol layer to a
          # Nokogiri object, if it contains XML (ie. Ozone).
          # FIXME: What happens if Nokogiri tries to parse non-XML string?
          if msg.is_a?(Dial)
            jid = @client_jid.domain
            iq = create_iq jid
            @logger.debug "Sending Command ID #{iq.id} #{msg.inspect} to #{jid}" if @logger
          else
            iq = create_iq "#{call.call_id}@#{@callmap[call.call_id]}"
            @logger.debug "Sending Command ID #{iq.id} #{msg.inspect} to #{call.call_id}" if @logger
          end
          iq << msg
          @result_queues[iq.id] = Queue.new
          write_to_stream msg
          result = read_queue_with_timeout @result_queues[iq.id]
          @result_queues[iq.id] = nil # Shut down this queue
          # FIXME: Error handling
          raise result if result.is_a? Exception
          true
        end

        def create_iq(jid = nil)
          Blather::Stanza::Iq.new(:set, jid || @call_id).tap do |iq|
            iq.from = @client_jid
          end
        end

        def run
          EM.run { client.run }
        end

        def connected?
          client.connected?
        end

        private

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

Dir[File.dirname(__FILE__) + '/ozone/*.rb'].each { |file| require file }
