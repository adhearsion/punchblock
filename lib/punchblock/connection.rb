module Punchblock
  module Connection
    extend ActiveSupport::Autoload

    autoload :Asterisk
    autoload :Connected
    autoload :XMPP
  end
end
