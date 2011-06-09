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
          super().tap do |new_node|
            new_node.headers = options[:headers]
          end
        end
      end # Hangup
    end # Ozone
  end # Protocol
end # Punchblock
