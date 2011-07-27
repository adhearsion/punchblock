module Punchblock
  module Protocol
    class Rayo
      module Command
        module Tropo
          extend ActiveSupport::Autoload

          autoload :Ask
          autoload :Conference
          autoload :Say
          autoload :Transfer
        end
      end # Command
    end # Rayo
  end # Protocol
end # Punchblock
