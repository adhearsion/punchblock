module Punchblock
  module Protocol
    class Rayo
      module Event
        class Unjoined < RayoNode
          register :unjoined, :core

          ##
          # @return [String] the call ID that was unjoined
          def other_call_id
            read_attr :'call-id'
          end

          ##
          # @return [String] the mixer name that was unjoined
          def mixer_id
            read_attr :'mixer-id'
          end

          def inspect_attributes # :nodoc:
            [:other_call_id, :mixer_id] + super
          end
        end # Unjoined
      end
    end # Rayo
  end # Protocol
end # Punchblock
