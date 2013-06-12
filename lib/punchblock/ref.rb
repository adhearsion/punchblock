# encoding: utf-8

module Punchblock
  ##
  # A rayo Ref message. This provides the command ID in response to execution of a command.
  #
  class Ref < RayoNode
    register :ref, :core

    # @return [String] the command URI
    attribute :uri

    def rayo_attributes
      {uri: uri}
    end
  end
end
