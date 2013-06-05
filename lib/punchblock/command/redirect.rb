# encoding: utf-8

module Punchblock
  module Command
    class Redirect < CommandNode
      register :redirect, :core

      include HasHeaders

      # @return [String] the redirect target
      attribute :to

      def rayo_attributes
        {'to' => to}
      end
    end
  end
end
