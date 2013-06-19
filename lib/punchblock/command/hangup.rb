# encoding: utf-8

module Punchblock
  module Command
    class Hangup < CommandNode
      register :hangup, :core

      include HasHeaders
    end
  end
end
