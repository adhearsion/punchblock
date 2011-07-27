module Punchblock
  module Protocol
    class Rayo
      module Event
        class DTMF < RayoNode
          register :dtmf, :core

          def signal
            read_attr :signal
          end

          def inspect_attributes # :nodoc:
            [:signal] + super
          end
        end # End
      end
    end # Rayo
  end # Protocol
end # Punchblock
