module Punchblock
  module Component
    extend ActiveSupport::Autoload

    autoload :Asterisk
    autoload :ComponentNode
    autoload :Input
    autoload :Output
    autoload :Record
    autoload :Stop
    autoload :Tropo

    InvalidActionError = Class.new StandardError
  end # Component
end # Punchblock
