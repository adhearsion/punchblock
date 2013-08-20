# encoding: utf-8

require 'ruby_jid'

module Punchblock
  ##
  # A rayo Ref message. This provides the command ID in response to execution of a command.
  #
  class Ref < RayoNode
    register :ref, :core

    # @return [String] the command URI
    attribute :uri, RubyJID
    def uri=(other)
      jid = URI(other).opaque
      super RubyJID.new(jid)
    end

    def rayo_attributes
      {}.tap do |atts|
        atts[:uri] = "xmpp:#{uri}" if uri
      end
    end
  end
end
