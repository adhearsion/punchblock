module Punchblock
  module Protocol
    module Ozone
      class Offer < Event
        register :offer, :core

        include HasHeaders

        def offer_to
          self[:to]
        end

        def offer_to=(offer_to)
          self[:to] = offer_to
        end

        def offer_from
          self[:from]
        end

        def offer_from=(offer_from)
          self[:from] = offer_from
        end
      end # Offer
    end # Ozone
  end # Protocol
end # Punchblock
