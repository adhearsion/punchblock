# encoding: utf-8

module Punchblock
  module Component
    extend ActiveSupport::Autoload

    autoload :Asterisk
    autoload :ComponentNode
    autoload :Input
    autoload :Output
    autoload :Prompt
    autoload :ReceiveFax
    autoload :Record
    autoload :SendFax
    autoload :Stop

    InvalidActionError = Class.new StandardError
  end # Component
end # Punchblock
