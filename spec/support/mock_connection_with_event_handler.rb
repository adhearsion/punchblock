# encoding: utf-8

# This is a nasty hack due to the fact that Mocha does not support expectations returning a value calculated by executing a block with the parameters passed.
# If it did, we could do this in our component tests:
# mc = mock 'Connection'
# mc.stubs(:handle_event).returns { |event| command.add_event event }
#
# Mocha does not support this feature because really, it's a smell in the tests
# We shouldn't really be mocking out behaviour like this if we actually need it to have side effects
# We only do this because of the difficulties in synchronising the tests with an asynchronous target in another thread.
#
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
