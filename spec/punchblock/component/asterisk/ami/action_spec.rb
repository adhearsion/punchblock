# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    module Asterisk
      module AMI
        describe Action do
          it 'registers itself' do
            RayoNode.class_from_registration(:action, 'urn:xmpp:rayo:asterisk:ami:1').should be == described_class
          end

          describe "from a stanza" do
            let :stanza do
              <<-MESSAGE
<action xmlns="urn:xmpp:rayo:asterisk:ami:1" name="Originate">
  <param name="Channel" value="SIP/101test"/>
  <param name="Context" value="default"/>
  <param name="Exten" value="8135551212"/>
  <param name="Priority" value="1"/>
  <param name="Callerid" value="3125551212"/>
  <param name="Timeout" value="30000"/>
  <param name="Variable" value="var1=23|var2=24|var3=25"/>
  <param name="Async" value="1"/>
</action>
              MESSAGE
            end

            subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of described_class }

            it_should_behave_like 'event'

            its(:name)    { should be == 'Originate' }
            its(:params)  { should be == { 'Channel'   => 'SIP/101test',
                                           'Context'   => 'default',
                                           'Exten'     => '8135551212',
                                           'Priority'  => '1',
                                           'Callerid'  => '3125551212',
                                           'Timeout'   => '30000',
                                           'Variable'  => 'var1=23|var2=24|var3=25',
                                           'Async'     => '1'} }
          end

          describe "testing equality" do
            context "with the same name and params" do
              it "should be equal" do
                Action.new(:name => 'Originate', :params => { :channel => 'SIP/101test' }).should be == Action.new(:name => 'Originate', :params => { :channel => 'SIP/101test' })
              end
            end

            context "with the same name and different params" do
              it "should be equal" do
                Action.new(:name => 'Originate', :params => { :channel => 'SIP/101' }).should_not be == Action.new(:name => 'Originate', :params => { :channel => 'SIP/101test' })
              end
            end

            context "with a different name and the same params" do
              it "should be equal" do
                Action.new(:name => 'Hangup', :params => { :channel => 'SIP/101test' }).should_not be == Action.new(:name => 'Originate', :params => { :channel => 'SIP/101test' })
              end
            end
          end

          describe "when setting options in initializer" do
            subject do
              described_class.new :name => 'Originate',
                                  :params => { 'Channel' => 'SIP/101test' }
            end

            its(:name)    { should be == 'Originate' }
            its(:params)  { should be == { 'Channel' => 'SIP/101test' } }

            describe "exporting to Rayo" do
              it "should export to XML that can be understood by its parser" do
                new_instance = RayoNode.from_xml subject.to_rayo
                new_instance.should be_instance_of described_class
                new_instance.name.should == 'Originate'
                new_instance.params.should == { 'Channel' => 'SIP/101test' }
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

          class Action
            class Complete
              describe Success do
                let :stanza do
                  <<-MESSAGE
<complete xmlns="urn:xmpp:rayo:ext:1">
  <success xmlns="urn:xmpp:rayo:asterisk:ami:complete:1">
    <message>Originate successfully queued</message>
    <text-body>Some thing happened</text-body>
    <attribute name="Channel" value="SIP/101-3f3f"/>
    <attribute name="State" value="Ring"/>
  </success>
</complete>
                  MESSAGE
                end

                subject { RayoNode.from_xml(parse_stanza(stanza).root).reason }

                it { should be_instance_of described_class }

                its(:name)    { should be == :success }
                its(:message) { should be == "Originate successfully queued" }
                its(:text_body) { should be == 'Some thing happened' }
                its(:headers) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} }
                its(:attributes) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} } # For BC

                describe "when setting options in initializer" do
                  subject do
                    described_class.new message: 'Originate successfully queued', text_body: 'Some thing happened', headers: {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'}
                  end

                  its(:message) { should be == 'Originate successfully queued' }
                  its(:text_body) { should be == 'Some thing happened' }
                  its(:headers) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} }
                  its(:attributes) { should be == {'Channel' => 'SIP/101-3f3f', 'State' => 'Ring'} } # For BC
                end
              end
            end
          end
        end
      end
    end
  end
end
