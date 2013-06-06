# encoding: utf-8

module Punchblock
  module Command
    class Unjoin < CommandNode
      register :unjoin, :core

      # @return [String] the call ID to unjoin
      attribute :call_id

      # @return [String] the mixer name to unjoin
      attribute :mixer_name

      def rayo_attributes
        {'call-id' => call_id, 'mixer-name' => mixer_name}
      end
    end
  end
end
