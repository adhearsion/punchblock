# encoding: utf-8

module Punchblock
  module Command
    class Hangup < CommandNode
      register :hangup, :core

      include HasHeaders

      ##
      # Create an Rayo hangup message
      #
      # @param [Hash] options
      # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
      #   the call. Can be either a hash of key-value pairs, or an array of
      #   Header objects.
      #
      # @return [Command::Hangup] a formatted Rayo redirect command
      #
      def self.new(options = {})
        super().tap do |new_node|
          new_node.headers = options[:headers]
        end
      end
    end # Hangup
  end # Command
end # Punchblock
