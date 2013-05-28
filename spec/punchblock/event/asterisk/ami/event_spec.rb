# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    module Asterisk
      module AMI
        describe Event do
          it 'registers itself' do
            RayoNode.class_from_registration(:event, 'urn:xmpp:rayo:asterisk:ami:1').should be == described_class
          end

          describe "from a stanza" do
            let :stanza do
              <<-MESSAGE
<event xmlns="urn:xmpp:rayo:asterisk:ami:1" name="Newchannel">
  <attribute name="Channel" value="SIP/101-3f3f"/>
  <attribute name="State" value="Ring"/>
</event>
              MESSAGE
            end

            subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Event }

            it_should_behave_like 'event'

            its(:name)    { should be == 'Newchannel' }
            its(:headers) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} }
            its(:attributes) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} } # For BC
          end

          describe "when setting options in initializer" do
            subject do
              described_class.new name: 'Newchannel',
                                  headers: {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}
            end

            its(:name)    { should be == 'Newchannel' }
            its(:headers) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} }
            its(:attributes) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} } # For BC

            describe "exporting to Rayo" do
              it "should export to XML that can be understood by its parser" do
                new_instance = RayoNode.from_xml subject.to_rayo
                new_instance.should be_instance_of described_class
                new_instance.name.should == 'Newchannel'
                new_instance.headers.should == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}
                new_instance.attributes.should == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} # For BC
              end

              it "should render to a parent node if supplied" do
                doc = Nokogiri::XML::Document.new
                parent = Nokogiri::XML::Node.new 'foo', doc
                doc.root = parent
                rayo_doc = subject.to_rayo(parent)
                rayo_doc.should == parent
              end
            end
          end
        end
      end
    end
  end
end
