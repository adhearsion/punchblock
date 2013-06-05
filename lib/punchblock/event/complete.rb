# encoding: utf-8

module Punchblock
  class Event
    class Complete < Event
      register :complete, :ext

      attribute :reason

      attribute :recording

      def inherit(xml_node)
        if reason_node = xml_node.at_xpath('*')
          self.reason = RayoNode.from_xml(reason_node).tap do |reason|
            reason.target_call_id = target_call_id
            reason.component_id = component_id
          end
        end

        if recording_node = xml_node.at_xpath('//ns:recording', ns: RAYO_NAMESPACES[:record_complete])
          self.recording = RayoNode.from_xml(recording_node).tap do |recording|
            recording.target_call_id = target_call_id
            recording.component_id = component_id
          end
        end

        super
      end

      class Reason < RayoNode
        attribute :name

        def inherit(xml_node)
          self.name = xml_node.name.to_sym
          super
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

        attribute :details

        def inherit(xml_node)
          self.details = xml_node.text.strip
          super
        end
      end
    end
  end
end
