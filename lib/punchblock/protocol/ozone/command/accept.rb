module Punchblock
  module Protocol
    class Ozone
      module Command
        class Accept < OzoneNode
          register :accept, :core

          include HasHeaders

          ##
          # Create an Ozone accept command. This is equivalent to a SIP "180 Trying"
          #
          # @param [Hash] options
          # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
          #   the call. Can be either a hash of key-value pairs, or an array of
          #   Header objects.
          #
          # @return [Ozone::Command::Accept] a formatted Ozone accept command
          #
          # @example
          #    Accept.new.to_xml
          #
          #    returns:
          #        <accept xmlns="urn:xmpp:ozone:1"/>
          def self.new(options = {})
            super().tap do |new_node|
              new_node.headers = options[:headers]
            end
          end
        end # Accept
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
