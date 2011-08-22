require 'spec_helper'

%w{
  blather/client/dsl
  punchblock/core_ext/blather/stanza
  punchblock/core_ext/blather/stanza/presence
}.each { |f| require f }

module Punchblock
  module Command
    describe Dial do

      it 'registers itself' do
        RayoNode.class_from_registration(:dial, 'urn:xmpp:rayo:1').should == Dial
      end

      describe "when setting options in initializer" do
        let(:join_params) { {:other_call_id => 'abc123'} }

        subject { Dial.new :to => 'tel:+14155551212', :from => 'tel:+13035551212', :headers => { :x_skill => 'agent', :x_customer_id => 8877 }, :join => join_params }

        it_should_behave_like 'command_headers'

        its(:to)    { should == 'tel:+14155551212' }
        its(:from)  { should == 'tel:+13035551212' }
        its(:join)  { should == Join.new(join_params) }
      end

      describe "#response=" do
        before { subject.request! }

        let(:call_id) { 'abc123' }

        let :ref do
          Ref.new.tap do |ref|
            ref.id = call_id
          end
        end

        let :iq do
          Blather::Stanza::Iq.new(:result, 'blah').tap do |iq|
            iq.from = "call.rayo.net"
            iq << ref
          end
        end

        it "should set the call ID from the ref" do
          subject.response = iq
          subject.call_id.should == call_id
        end
      end
    end
  end
end # Punchblock
