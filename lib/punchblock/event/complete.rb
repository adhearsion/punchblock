module Punchblock
  module Event
    class Complete < RayoNode
      # TODO: Validate response and return response type.
      # -----
      # <complete xmlns="urn:xmpp:rayo:ext:1"/>

      register :complete, :ext

      def reason
        element = find_first('*')
        if element
          RayoNode.import(element).tap do |reason|
            reason.call_id = call_id
            reason.component_id = component_id
          end
        end
      end

      def recording
        element = find_first('//ns:recording', :ns => RAYO_NAMESPACES[:record_complete])
        if element
          RayoNode.import(element).tap do |recording|
            recording.call_id = call_id
            recording.component_id = component_id
          end
        end
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
end # Punchblock
