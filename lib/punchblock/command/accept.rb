# encoding: utf-8

module Punchblock
  module Command
    class Accept < CommandNode
      register :accept, :core

      include HasHeaders

      ##
      # Create an Rayo accept command. This is equivalent to a SIP "180 Trying"
      #
      # @param [Hash] options
      # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
      #   the call. Can be either a hash of key-value pairs, or an array of
      #   Header objects.
      #
      # @return [Command::Accept] a formatted Rayo accept command
      #
      # @example
      #    Accept.new.to_xml
      #
      #    returns:
      #        <accept xmlns="urn:xmpp:rayo:1"/>
      def self.new(options = {})
        super().tap do |new_node|
          new_node.headers = options[:headers]
        end
      end
    end # Accept
  end # Command
end # Punchblock
