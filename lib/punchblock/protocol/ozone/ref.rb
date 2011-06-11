module Punchblock
  module Protocol
    module Ozone
      class Ref < OzoneNode
        register :ref, :core

        def id
          read_attr :id
        end

        def id=(ref_id)
          write_attr :id, ref_id
        end

        def attributes
          [:id] + super
        end
      end # Offer
    end # Ozone
  end # Protocol
end # Punchblock
