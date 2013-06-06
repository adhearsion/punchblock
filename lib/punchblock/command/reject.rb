# encoding: utf-8

module Punchblock
  module Command
    class Reject < CommandNode
      register :reject, :core

      include HasHeaders

      VALID_REASONS = [:busy, :decline, :error].freeze

      # @return [Symbol] the reason type for rejecting a call. One of :busy, :dclined or :error.
      # @raises ArgumentError if reject_reason is not one of the allowed reasons
      attribute :reason, Symbol
      def reason=(reject_reason)
        if reject_reason && !VALID_REASONS.include?(reject_reason.to_sym)
          raise ArgumentError, "Invalid Reason (#{reject_reason}), use: #{VALID_REASONS*' '}"
        end
        super
      end

      def inherit(xml_node)
        if first_child = xml_node.at_xpath('*')
          self.reason = first_child.name
        end
        super
      end

      def rayo_children(root)
        root.send reason if reason
        super
      end
    end
  end
end
