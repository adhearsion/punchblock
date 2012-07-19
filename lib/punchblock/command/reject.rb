# encoding: utf-8

module Punchblock
  module Command
    class Reject < CommandNode
      register :reject, :core

      include HasHeaders

      VALID_REASONS = [:busy, :decline, :error].freeze

      ##
      # Create an Rayo reject message
      #
      # @param [Hash] options
      # @option options [Symbol] :reason for rejecting the call. Can be any one of VALID_REASONS. Defaults to :decline
      # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
      #   the call. Can be either a hash of key-value pairs, or an array of
      #   Header objects.
      #
      # @return [Command::Reject] a formatted Rayo reject command
      #
      # @example
      #    Reject.new(:reason => :busy).to_xml
      #
      #    returns:
      #        <reject xmlns="urn:xmpp:rayo:1"><busy/></reject
      #
      def self.new(options = {})
        super().tap do |new_node|
          case options
          when Nokogiri::XML::Node
            new_node.inherit options
          when Hash
            options.each_pair { |k,v| new_node.send :"#{k}=", v }
          end
        end
      end

      ##
      # @return [Symbol] the reason type for rejecting a call
      #
      def reason
        node = reason_node
        node ? node.name.to_sym : nil
      end

      ##
      # Set the reason for rejecting the call
      #
      # @param [Symbol] reject_reason Can be any one of :busy, :dclined or :error.
      #
      # @raises ArgumentError if reject_reason is not one of the allowed reasons
      #
      def reason=(reject_reason)
        if reject_reason && !VALID_REASONS.include?(reject_reason.to_sym)
          raise ArgumentError, "Invalid Reason (#{reject_reason}), use: #{VALID_REASONS*' '}"
        end
        children.each(&:remove)
        self << RayoNode.new(reject_reason)
      end

      def inspect_attributes # :nodoc:
        [:reason] + super
      end

      private

      def reason_node
        node_children = children.select { |c| [Nokogiri::XML::Element, Niceogiri::XML::Node].any? { |k| c.is_a?(k) } }
        node_children.first
      end
    end # Reject
  end # Command
end # Punchblock
