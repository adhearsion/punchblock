# encoding: utf-8

module Punchblock
  class Client
    class ComponentRegistry
      def initialize
        @mutex = Mutex.new
        @components = Hash.new
      end

      def <<(component)
        @mutex.synchronize do
          @components[component.key] = component
        end
      end

      def find_by_key(key)
        @mutex.synchronize do
          @components[key]
        end
      end

      def delete(component)
        @mutex.synchronize do
          id = @components.key component
          @components.delete id
        end
      end
    end
  end
end
