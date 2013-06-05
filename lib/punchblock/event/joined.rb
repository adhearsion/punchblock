# encoding: utf-8

module Punchblock
  class Event
    class Joined < Event
      register :joined, :core

      # @return [String] the call ID that was joined
      attribute :call_id

      # @return [String] the mixer name that was joined
      attribute :mixer_name
    end
  end
end
