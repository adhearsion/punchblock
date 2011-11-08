module Punchblock
  module Translator
    class Asterisk
      class Call
        include Celluloid

        def initialize
          @components = {}
        end

        def register_component(component)
          @components[component.id] ||= component
        end

        def component_with_id(component_id)
          @components[component_id]
        end

        def execute_component_command(command)
          component_with_id(command.component_id).execute_command command
        end
      end
    end
  end
end
