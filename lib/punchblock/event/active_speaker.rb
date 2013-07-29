# encoding: utf-8

module Punchblock
  class Event
    module ActiveSpeaker
      def self.included(klass)
        klass.attribute :call_id
      end
    end
  end
end
