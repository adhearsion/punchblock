module Punchblock
  module Protocol
    class Rayo
      module Event
        class Complete < RayoNode
          # TODO: Validate response and return response type.
          # -----
          # <complete xmlns="urn:xmpp:rayo:ext:1"/>

          register :complete, :ext

          def reason
            element = find_first('*')
            RayoNode.import element if element
          end

          def recording
            element = find_first('//ns:recording', :ns => OZONE_NAMESPACES[:record_complete])
            RayoNode.import element if element
          end

          def inspect_attributes # :nodoc:
            [:reason, :recording] + super
          end

          class Reason < RayoNode
            def name
              super.to_sym
            end

            def inspect_attributes # :nodoc:
              [:name] + super
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

            def inspect_attributes # :nodoc:
              [:details] + super
            end
          end
        end # Complete
      end
    end # Rayo
  end # Protocol
end # Punchblock
