module Punchblock
  module Protocol
    class Ozone
      module Command
        class Dial < OzoneNode
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
          #
          # @return [Ozone::Command::Dial] a formatted Ozone dial command
          #
          # @example
          #    dial :to => 'tel:+14155551212', :from => 'tel:+13035551212'
          #
          #    returns:
          #      <dial to='tel:+13055195825' from='tel:+14152226789' xmlns='urn:xmpp:ozone:1' />
          #
          def self.new(options = {})
            super().tap do |new_node|
              new_node.to = options[:to]
              new_node.from = options[:from]
              new_node.headers = options[:headers]
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

          def attributes # :nodoc:
            [:to, :from] + super
          end
        end # Dial
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
