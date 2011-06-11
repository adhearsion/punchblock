module Punchblock
  module Protocol
    module Ozone
      module Command
        ##
        # An Ozone reject message
        #
        # @example
        #    Reject.new.to_xml
        #
        #    returns:
        #        <reject xmlns="urn:xmpp:ozone:1"/>
        class Reject < OzoneNode
          register :reject, :core

          include HasHeaders

          VALID_REASONS = [:busy, :declined, :error].freeze

          # Overrides the parent to ensure a reject node is created
          # @private
          def self.new(options = {})
            super().tap do |new_node|
              new_node.reason = options[:reason] || :declined
              new_node.headers = options[:headers]
            end
          end

          def reason
            children.select { |c| c.is_a? Nokogiri::XML::Element }.first.name.to_sym
          end

          def reason=(reject_reason)
            if reject_reason && !VALID_REASONS.include?(reject_reason.to_sym)
              raise ArgumentError, "Invalid Reason (#{reject_reason}), use: #{VALID_REASONS*' '}"
            end
            children.each &:remove
            self << OzoneNode.new(reject_reason)
          end

          def attributes
            [:reason] + super
          end
        end # Reject
      end
    end # Ozone
  end # Protocol
end # Punchblock
