# encoding: utf-8

module Punchblock
  class Event
    class End < Event
      register :end, :core

      include HasHeaders

      attribute :reason, Symbol

      def inherit(xml_node)
        if reason_node = xml_node.at_xpath('*')
          self.reason = reason_node.name
        end
        super
      end
    end
  end
end
