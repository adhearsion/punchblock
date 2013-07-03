# encoding: utf-8

module Punchblock
  class Client
    class ComponentRegistry
      def initialize
        @components = Hash.new
      end

      def <<(component)
        @components[component.component_id] = component
      end

      def find_by_id(component_id)
        @components[component_id]
      end

      def delete(component)
        id = @components.key component
        @components.delete id
      end
    end
  end
end
