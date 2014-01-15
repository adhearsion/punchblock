# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe ReceiveFax do
      it 'registers itself' do
        RayoNode.class_from_registration(:receivefax, 'urn:xmpp:rayo:fax:1').should be == described_class
      end

      describe "exporting to Rayo" do
        it "should export to XML that can be understood by its parser" do
          new_instance = RayoNode.from_xml subject.to_rayo
          new_instance.should be_instance_of described_class
        end

        it "should render to a parent node if supplied" do
          doc = Nokogiri::XML::Document.new
          parent = Nokogiri::XML::Node.new 'foo', doc
          doc.root = parent
          rayo_doc = subject.to_rayo(parent)
          rayo_doc.should == parent
        end
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<receivefax xmlns="urn:xmpp:rayo:fax:1"/>
          MESSAGE
        end

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of described_class }
      end

      describe "actions" do
        let(:mock_client) { double 'Client' }
        let(:command) { described_class.new }

        before do
          command.component_id = 'abc123'
          command.target_call_id = '123abc'
          command.client = mock_client
        end

        describe '#stop_action' do
          subject { command.stop_action }

          its(:to_xml) { should be == '<stop xmlns="urn:xmpp:rayo:ext:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:target_call_id) { should be == '123abc' }
        end

        describe '#stop!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.should_receive(:execute_command).with(command.stop_action, :target_call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a ReceiveFax that is new")
            end
          end
        end
      end

      describe ReceiveFax::Complete::Finish do
        let :stanza do
          <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
  <finish xmlns='urn:xmpp:rayo:fax:complete:1'/>
  <fax xmlns='urn:xmpp:rayo:fax:complete:1' url='http://shakespere.lit/faxes/fax1.tiff' resolution='595x841' size='12287492817' pages='3'/>
  <metadata xmlns='urn:xmpp:rayo:fax:complete:1' name="fax-transfer-rate" value="10000" />
  <metadata xmlns='urn:xmpp:rayo:fax:complete:1' name="foo" value="true" />
</complete>
          MESSAGE
        end

        subject(:complete_node) { RayoNode.from_xml(parse_stanza(stanza).root) }

        it "should understand a finish reason" do
          subject.reason.should be_instance_of ReceiveFax::Complete::Finish
        end

        describe "should make the fax data available" do
          subject { complete_node.fax }

          it { should be_instance_of ReceiveFax::Fax }

          its(:url)         { should be == 'http://shakespere.lit/faxes/fax1.tiff' }
          its(:resolution)  { should be == '595x841' }
          its(:pages)       { should be == 3 }
          its(:size)        { should be == 12287492817 }
        end

        its(:fax_metadata) { should == {'fax-transfer-rate' => '10000', 'foo' => 'true'} }
      end
    end
  end
end
