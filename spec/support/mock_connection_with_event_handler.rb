# encoding: utf-8

module HasMockCallbackConnection
  def self.included(test_case)
    test_case.let(:connection) do
      double('Connection').tap do |mc|
        allow(mc).to receive :handle_event do |event|
          original_command.add_event event
        end
      end
    end
  end
end
