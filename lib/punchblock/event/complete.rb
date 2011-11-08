module Punchblock
  class Event
    class Complete < Event
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

      def reason=(other)
        children.map &:remove
        self << other
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

        def details=(other)
          self << other
        end

        def inspect_attributes # :nodoc:
          [:details] + super
        end
      end
    end # Complete
  end
end # Punchblock
