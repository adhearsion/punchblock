# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Reject do
      it 'registers itself' do
        RayoNode.class_from_registration(:reject, 'urn:xmpp:rayo:1').should be == Reject
      end

      describe "when setting options in initializer" do
        subject { Reject.new :reason => :busy, :headers => { :x_skill => 'agent', :x_customer_id => 8877 } }

        it_should_behave_like 'command_headers'

        its(:reason) { should be == :busy }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<reject xmlns='urn:xmpp:rayo:1'>
  <busy />
  <!-- Sample Headers (optional) -->
  <header name="x-reason-internal" value="bad-skill" />
</reject>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Reject }

        its(:reason) { should be == :busy }
        its(:headers_hash) { should be == { :x_reason_internal => 'bad-skill' } }
      end

      describe "with the reason" do
        [nil, :decline, :busy, :error].each do |reason|
          describe reason do
            subject { Reject.new :reason => reason }

            its(:reason) { should be == reason }
          end
        end

        describe "no reason" do
          subject { Reject.new }

          its(:reason) { should be_nil }
        end

        describe "blahblahblah" do
          it "should raise an error" do
            expect { Reject.new(:reason => :blahblahblah) }.to raise_error ArgumentError
          end
        end
      end
    end
  end
end # Punchblock
