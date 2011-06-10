module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone redirect message
      #
      # @example
      #    Redirect.new('tel:+14045551234').to_xml
      #
      #    returns:
      #        <redirect to="tel:+14045551234" xmlns="urn:xmpp:ozone:1"/>
      class Redirect < Command
        register :redirect, :core

        include HasHeaders

        def self.new(to = '', options = {})
          super().tap do |new_node|
            new_node.to = to
            new_node.headers = options[:headers]
          end
        end

        def to
          read_attr :to
        end

        def to=(redirect_to)
          write_attr :to, redirect_to
        end

        def attributes
          [:to] + super
        end
      end # Redirect
    end # Ozone
  end # Protocol
end # Punchblock
