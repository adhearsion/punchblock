# encoding: utf-8

module Punchblock
  module Command
    extend ActiveSupport::Autoload

    autoload :Accept
    autoload :Answer
    autoload :Dial
    autoload :Hangup
    autoload :Join
    autoload :Mute
    autoload :Redirect
    autoload :Reject
    autoload :Unjoin
    autoload :Unmute
  end # Command
end # Punchblock
