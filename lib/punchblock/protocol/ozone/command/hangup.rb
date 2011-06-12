module Punchblock
  module Protocol
    class Ozone
      module Command
        class Hangup < OzoneNode
          register :hangup, :core

          include HasHeaders

          ##
          # Create an Ozone hangup message
          #
          # @param [Hash] options
          # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
          #   the call. Can be either a hash of key-value pairs, or an array of
          #   Header objects.
          #
          # @return [Ozone::Command::Hangup] a formatted Ozone redirect command
          #
          def self.new(options = {})
            super().tap do |new_node|
              new_node.headers = options[:headers]
            end
          end
        end # Hangup
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
