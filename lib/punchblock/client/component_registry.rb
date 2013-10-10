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
          @components[component.uri] = component
        end
      end

      def find_by_uri(uri)
        @mutex.synchronize do
          @components[uri]
        end
      end

      def delete(component)
        @mutex.synchronize do
          uri = @components.key component
          @components.delete uri
        end
      end
    end
  end
end
