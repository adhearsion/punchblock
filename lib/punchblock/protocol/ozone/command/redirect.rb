module Punchblock
  module Protocol
    class Ozone
      module Command
        class Redirect < OzoneNode
          register :redirect, :core

          include HasHeaders

          ##
          # Create an Ozone redirect message
          #
          # @param [Hash] options
          # @option options [String] :to redirect target
          # @option options [Array[Header], Hash, Optional] :headers SIP headers to attach to
          #   the new call. Can be either a hash of key-value pairs, or an array of
          #   Header objects.
          #
          # @return [Ozone::Command::Redirect] a formatted Ozone redirect command
          #
          # @example
          #    Redirect.new(:to => 'tel:+14045551234').to_xml
          #
          #    returns:
          #        <redirect to="tel:+14045551234" xmlns="urn:xmpp:ozone:1"/>
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

          def attributes # :nodoc:
            [:to] + super
          end
        end # Redirect
      end # Command
    end # Ozone
  end # Protocol
end # Punchblock
