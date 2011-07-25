module Punchblock
  module Protocol
    class Rayo
      module Command
        class Redirect < CommandNode
          register :redirect, :core

          include HasHeaders

          ##
          # Create an Rayo redirect message
          #
          # @param [Hash] options
          # @option options [String] :to redirect target
          # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
          #   the new call. Can be either a hash of key-value pairs, or an array of
          #   Header objects.
          #
          # @return [Rayo::Command::Redirect] a formatted Rayo redirect command
          #
          # @example
          #    Redirect.new(:to => 'tel:+14045551234').to_xml
          #
          #    returns:
          #        <redirect to="tel:+14045551234" xmlns="urn:xmpp:rayo:1"/>
          #
          def self.new(options = {})
            super().tap do |new_node|
              new_node.to = options[:to]
              new_node.headers = options[:headers]
            end
          end

          ##
          # @return [String] the redirect target
          def to
            read_attr :to
          end

          ##
          # @param [String] redirect_to redirect target
          def to=(redirect_to)
            write_attr :to, redirect_to
          end

          def inspect_attributes # :nodoc:
            [:to] + super
          end
        end # Redirect
      end # Command
    end # Rayo
  end # Protocol
end # Punchblock
