# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Command
    describe Dial do

      it 'registers itself' do
        RayoNode.class_from_registration(:dial, 'urn:xmpp:rayo:1').should be == described_class
      end

      let(:join_params) { {:call_uri => 'abc123'} }

      describe "when setting options in initializer" do
        subject { described_class.new to: 'tel:+14155551212', from: 'tel:+13035551212', timeout: 30000, headers: { 'X-skill' => 'agent', 'X-customer-id' => '8877' }, join: join_params }

        its(:to)      { should be == 'tel:+14155551212' }
        its(:from)    { should be == 'tel:+13035551212' }
        its(:timeout) { should be == 30000 }
        its(:join)    { should be == Join.new(join_params) }
        its(:headers) { should be == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml subject.to_rayo
            new_instance.should be_instance_of described_class
            new_instance.to.should == 'tel:+14155551212'
            new_instance.from.should == 'tel:+13035551212'
            new_instance.timeout.should == 30000
            new_instance.join.should == Join.new(join_params)
            new_instance.headers.should == { 'X-skill' => 'agent', 'X-customer-id' => '8877' }
          end

          it "should render to a parent node if supplied" do
            doc = Nokogiri::XML::Document.new
            parent = Nokogiri::XML::Node.new 'foo', doc
            doc.root = parent
            rayo_doc = subject.to_rayo(parent)
            rayo_doc.should == parent
          end

          context "when attributes are not set" do
            subject { described_class.new to: 'abc123' }

            it "should not include them in the XML representation" do
              subject.to_rayo['to'].should == 'abc123'
              subject.to_rayo['from'].should be_nil
            end
          end
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<dial to='tel:+14155551212' from='tel:+13035551212' timeout='30000' xmlns='urn:xmpp:rayo:1'>
  <join call-uri="abc123" />
  <header name="X-skill" value="agent" />
  <header name="X-customer-id" value="8877" />
</dial>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }

        its(:to)      { should be == 'tel:+14155551212' }
        its(:from)    { should be == 'tel:+13035551212' }
        its(:timeout) { should be == 30000 }
        its(:join)    { should be == Join.new(join_params) }
        its(:headers) { should be == { 'X-skill' => 'agent', 'X-customer-id' => '8877' } }

        context "with no headers provided" do
          let(:stanza) { '<dial xmlns="urn:xmpp:rayo:1"/>' }

          its(:headers) { should == {} }
        end
      end

      describe "#response=" do
        before { subject.request! }

        let(:call_id) { 'abc123' }
        let(:domain)  { 'rayo.net' }

        let :ref do
          Ref.new uri: "xmpp:#{call_id}@#{domain}"
        end

        it "should set the call ID from the ref" do
          subject.response = ref
          subject.target_call_id.should be == call_id
        end

        it "should set the domain from the ref" do
          subject.response = ref
          subject.domain.should be == domain
        end
      end
    end
  end
end
