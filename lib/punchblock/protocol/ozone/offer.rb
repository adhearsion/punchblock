module Punchblock
  module Protocol
    module Ozone
      class Offer < Event
        register :offer, :core

        include HasHeaders

        def offer_to
          read_attr :to
        end

        def offer_to=(offer_to)
          write_attr :to, offer_to
        end

        def offer_from
          read_attr :from
        end

        def offer_from=(offer_from)
          write_attr :from, offer_from
        end
      end # Offer
    end # Ozone
  end # Protocol
end # Punchblock
