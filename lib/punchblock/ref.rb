# encoding: utf-8

module Punchblock
  ##
  # A rayo Ref message. This provides the command ID in response to execution of a command.
  #
  class Ref < RayoNode
    register :ref, :core

    # @return [String] the command ID
    attribute :id

    def rayo_attributes
      {id: id}
    end
  end
end
