# encoding: utf-8

module Punchblock
  module Connection
    extend ActiveSupport::Autoload

    autoload :Asterisk
    autoload :Connected
    autoload :GenericConnection
    autoload :XMPP
  end
end
