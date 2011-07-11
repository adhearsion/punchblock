module Punchblock
  module Protocol
    class Ozone
      module Event
        class DTMF < OzoneNode
          register :dtmf, :core

          def signal
            read_attr :signal
          end

          def inspect_attributes # :nodoc:
            [:signal] + super
          end
        end # End
      end
    end # Ozone
  end # Protocol
end # Punchblock
