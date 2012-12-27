# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Join do

      it 'registers itself' do
        RayoNode.class_from_registration(:join, 'urn:xmpp:rayo:1').should be == Join
      end

      describe "when setting options in initializer" do
        subject { Join.new :call_id => 'abc123', :mixer_name => 'blah', :direction => :duplex, :media => :bridge }

        its(:call_id)     { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
        its(:direction)   { should be == :duplex }
        its(:media)       { should be == :bridge }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<join xmlns="urn:xmpp:rayo:1"
      call-id="abc123"
      mixer-name="blah"
      direction="duplex"
      media="bridge" />
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Join }

        its(:call_id)     { should be == 'abc123' }
        its(:mixer_name)  { should be == 'blah' }
        its(:direction)   { should be == :duplex }
        its(:media)       { should be == :bridge }
      end

      describe "with a direction" do
        [nil, :duplex, :send, :recv].each do |direction|
          describe direction do
            subject { Join.new :direction => direction }

            its(:direction) { should be == direction }
          end
        end

        describe "no direction" do
          subject { Join.new }

          its(:direction) { should be_nil }
        end

        describe "blahblahblah" do
          it "should raise an error" do
            expect { Join.new(:direction => :blahblahblah) }.to raise_error ArgumentError
          end
        end
      end
    end
  end
end # Punchblock
