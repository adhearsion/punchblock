# encoding: utf-8

module Punchblock
  module Translator
    extend ActiveSupport::Autoload

    OptionError = Class.new Punchblock::Error

    autoload :Asterisk

    autoload :DTMFRecognizer
    autoload :InputComponent
  end
end
