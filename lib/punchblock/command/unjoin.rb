# encoding: utf-8

module Punchblock
  module Command
    class Unjoin < CommandNode
      register :unjoin, :core

      ##
      # Create an ujoin message
      #
      # @param [Hash] options
      # @option options [String, Optional] :call_id the call ID to unjoin
      # @option options [String, Optional] :mixer_name the mixer name to unjoin
      #
      # @return [Command::Unjoin] a formatted Rayo unjoin command
      #
      def self.new(options = {})
        super().tap do |new_node|
          options.each_pair { |k,v| new_node.send :"#{k}=", v }
        end
      end

      ##
      # @return [String] the call ID to unjoin
      def call_id
        read_attr :'call-id'
      end

      ##
      # @param [String] other the call ID to unjoin
      def call_id=(other)
        write_attr :'call-id', other
      end

      ##
      # @return [String] the mixer name to unjoin
      def mixer_name
        read_attr :'mixer-name'
      end

      ##
      # @param [String] other the mixer name to unjoin
      def mixer_name=(other)
        write_attr :'mixer-name', other
      end

      def inspect_attributes # :nodoc:
        [:call_id, :mixer_name] + super
      end
    end # Unjoin
  end # Command
end # Punchblock
