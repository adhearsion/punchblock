require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Reject do
        let :expected_message do
          <<-MESSAGE
<reject xmlns="urn:xmpp:ozone:1">
  <declined/>
</reject>
          MESSAGE
        end

        its(:to_xml) { should == expected_message.chomp }

        describe "with the reason" do
          [:declined, :busy, :error].each do |reason|
            describe reason do
              subject { Reject.new reason }

              let :expected_message do
                <<-MESSAGE
<reject xmlns="urn:xmpp:ozone:1">
  <#{reason}/>
</reject>
                MESSAGE
              end

              its(:to_xml) { should == expected_message.chomp }
            end
          end

          it "blahblahblah" do
            expect { Reject.new(:blahblahblah) }.to raise_error ArgumentError
          end
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
