# encoding: utf-8

module Punchblock
  module Command
    class Answer < CommandNode
      register :answer, :core

      include HasHeaders

      ##
      # Create an Rayo answer command. This is equivalent to a SIP "200 OK"
      #
      # @param [Hash] options
      # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
      #   the call. Can be either a hash of key-value pairs, or an array of
      #   Header objects.
      #
      # @return [Command::Answer] a formatted Rayo answer command
      #
      # @example
      #    Answer.new.to_xml
      #
      #    returns:
      #        <answer xmlns="urn:xmpp:rayo:1"/>
      def self.new(options = {})
        super().tap do |new_node|
          new_node.headers = options[:headers]
        end
      end
    end # Answer
  end # Command
end # Punchblock
