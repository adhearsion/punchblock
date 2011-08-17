module Punchblock
  class Rayo
    module Command
      class Dial < CommandNode
        register :dial, :core

        include HasHeaders

        ##
        # Create a dial message
        #
        # @param [Hash] options
        # @option options [String] :to destination to dial
        # @option options [String, Optional] :from what to set the Caller ID to
        # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
        #   the new call. Can be either a hash of key-value pairs, or an array of
        #   Header objects.
        # @option options [Join, Hash, Optional] :join a join (or set of join parameters) to
        #   nest within the dial
        #
        # @return [Rayo::Command::Dial] a formatted Rayo dial command
        #
        # @example
        #    dial :to => 'tel:+14155551212', :from => 'tel:+13035551212'
        #
        #    returns:
        #      <dial to='tel:+13055195825' from='tel:+14152226789' xmlns='urn:xmpp:rayo:1' />
        #
        def self.new(options = {})
          super().tap do |new_node|
            options.each_pair { |k,v| new_node.send :"#{k}=", v }
          end
        end

        ##
        # @return [String] destination to dial
        def to
          read_attr :to
        end

        ##
        # @param [String] dial_to destination to dial
        def to=(dial_to)
          write_attr :to, dial_to
        end

        ##
        # @return [String] the caller ID
        def from
          read_attr :from
        end

        ##
        # @param [String] dial_from what to set the caller ID to
        def from=(dial_from)
          write_attr :from, dial_from
        end

        ##
        # @return [Join] the nested join
        #
        def join
          element = find_first 'ns:join', :ns => Join.registered_ns
          Join.new element if element
        end

        ##
        # @param [Hash, Join] other a join or hash of join options
        #
        def join=(other)
          remove_children :join
          join = Join.new(other) unless other.is_a?(Join)
          self << join
        end

        def response=(other)
          super
          if other.is_a?(Blather::Stanza::Iq)
            ref = other.rayo_node
            @call_id = ref.id if ref.is_a?(Ref)
          end
        end

        def inspect_attributes # :nodoc:
          [:to, :from, :join] + super
        end
      end # Dial
    end # Command
  end # Rayo
end # Punchblock
