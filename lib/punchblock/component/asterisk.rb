# encoding: utf-8

module Punchblock
  module Component
    module Asterisk
      extend ActiveSupport::Autoload

      autoload :AGI
      autoload :AMI
    end
  end # Command
end # Punchblock
