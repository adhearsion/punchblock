require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      module Command
        describe Reject do
          it 'registers itself' do
            OzoneNode.class_from_registration(:reject, 'urn:xmpp:ozone:1').should == Reject
          end

          describe "when setting options in initializer" do
            subject { Reject.new :reason => :busy, :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

            it_should_behave_like 'command_headers'

            its(:reason) { should == :busy }
          end

          describe "with the reason" do
            [:declined, :busy, :error].each do |reason|
              describe reason do
                subject { Reject.new :reason => reason }

                let :expected_message do
                  <<-MESSAGE
  <reject xmlns="urn:xmpp:ozone:1">
    <#{reason}/>
  </reject>
                  MESSAGE
                end

                its(:reason) { should == reason }
              end
            end

            describe "blahblahblah" do
              it "should raise an error" do
                expect { Reject.new(:reason => :blahblahblah) }.to raise_error ArgumentError
              end
            end
          end
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
