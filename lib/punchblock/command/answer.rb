# encoding: utf-8

module Punchblock
  module Command
    class Answer < CommandNode
      register :answer, :core

      include HasHeaders
    end
  end
end
