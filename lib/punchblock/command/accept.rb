# encoding: utf-8

module Punchblock
  module Command
    class Accept < CommandNode
      register :accept, :core

      include HasHeaders
    end
  end
end
