# encoding: utf-8

module Punchblock
  class Event
    class Unjoined < Event
      register :unjoined, :core

      # @return [String] the call ID that was unjoined
      attribute :call_id

      # @return [String] the mixer name that was unjoined
      attribute :mixer_name
    end
  end
end
