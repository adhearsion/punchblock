require 'spec_helper'

module Punchblock
  module Command
    describe Dial do

      it 'registers itself' do
        RayoNode.class_from_registration(:dial, 'urn:xmpp:rayo:1').should == Dial
      end

      let(:join_params) { {:other_call_id => 'abc123'} }

      describe "when setting options in initializer" do
        subject { Dial.new :to => 'tel:+14155551212', :from => 'tel:+13035551212', :timeout => 30000, :headers => { :x_skill => 'agent', :x_customer_id => 8877 }, :join => join_params }

        it_should_behave_like 'command_headers'

        its(:to)      { should == 'tel:+14155551212' }
        its(:from)    { should == 'tel:+13035551212' }
        its(:timeout) { should == 30000 }
        its(:join)    { should == Join.new(join_params) }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<dial to='tel:+14155551212' from='tel:+13035551212' timeout='30000' xmlns='urn:xmpp:rayo:1'>
  <join call-id="abc123" />
  <header name="x-skill" value="agent" />
  <header name="x-customer-id" value="8877" />
</dial>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Dial }

        its(:to)      { should == 'tel:+14155551212' }
        its(:from)    { should == 'tel:+13035551212' }
        its(:timeout) { should == 30000 }
        its(:join)    { should == Join.new(join_params) }
      end

      describe "#response=" do
        before { subject.request! }

        let(:call_id) { 'abc123' }

        let :ref do
          Ref.new.tap do |ref|
            ref.id = call_id
          end
        end

        it "should set the call ID from the ref" do
          subject.response = ref
          subject.call_id.should == call_id
        end
      end
    end
  end
end # Punchblock
