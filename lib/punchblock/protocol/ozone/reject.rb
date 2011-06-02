module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone reject message
      #
      # @example
      #    Reject.new.to_xml
      #
      #    returns:
      #        <reject xmlns="urn:xmpp:ozone:1"/>
      class Reject < Message
        def self.new(reason = :declined)
          raise ArgumentError unless [:busy, :declined, :error].include? reason
          super('reject').tap do |msg|
            Nokogiri::XML::Builder.with(msg.instance_variable_get(:@xml)) do |xml|
              xml.send reason.to_sym
            end
          end
        end
      end # Reject
    end # Ozone
  end # Protocol
end # Punchblock
