def mock_connection_with_event_handler(&block)
  mock('Connection').tap do |mc|
    class << mc
      attr_accessor :target
    end

    mc.target = block

    def mc.handle_event(event)
      target.call event
    end
  end
end
