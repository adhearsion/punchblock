module Punchblock
  module Protocol
    class Ozone
      module Command
        class Answer < OzoneNode
          register :answer, :core

          include HasHeaders

          ##
          # Create an Ozone answer command. This is equivalent to a SIP "200 OK"
          #
          # @param [Hash] options
          # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
          #   the call. Can be either a hash of key-value pairs, or an array of
          #   Header objects.
          #
          # @return [Ozone::Command::Answer] a formatted Ozone answer command
          #
          # @example
          #    Answer.new.to_xml
          #
          #    returns:
          #        <answer xmlns="urn:xmpp:ozone:1"/>
          def self.new(options = {})
            super().tap do |new_node|
              new_node.headers = options[:headers]
            end
          end
        end # Answer
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
