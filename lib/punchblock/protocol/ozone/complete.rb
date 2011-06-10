module Punchblock
  module Protocol
    module Ozone
      class Complete < Event
        # TODO: Validate response and return response type.
        # -----
        # <complete xmlns="urn:xmpp:ozone:ext:1"/>

        register :complete, :ext

        def reason
          Event.import children.select { |c| c.is_a? Nokogiri::XML::Element }.first
        end

        class Reason < OzoneNode
          def name
            super.to_sym
          end
        end

        class Stop < Reason
          register :stop, :ext_complete
        end

        class Hangup < Reason
          register :hangup, :ext_complete
        end

        class Error < Reason
          register :error, :ext_complete

          def details
            text.strip
          end
        end
      end # Complete
    end # Ozone
  end # Protocol
end # Punchblock
