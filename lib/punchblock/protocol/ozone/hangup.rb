module Punchblock
  module Protocol
    module Ozone
      ##
      # An Ozone hangup message
      #
      class Hangup < Command
        register :hangup, :core

        include HasHeaders

        def self.new(options = {})
          new_node = super()
          new_node.headers = options[:headers]
          new_node
        end
      end # Hangup
    end # Ozone
  end # Protocol
end # Punchblock
