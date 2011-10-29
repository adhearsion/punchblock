module Punchblock
  module Connection
    Connected = Class.new do
      class << self
        def source
          nil
        end

        def client=(other)
          nil
        end
      end
    end
  end
end
