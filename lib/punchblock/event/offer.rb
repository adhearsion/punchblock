# encoding: utf-8

module Punchblock
  class Event
    class Offer < Event
      register :offer, :core

      include HasHeaders

      attribute :to
      attribute :from
    end
  end
end
