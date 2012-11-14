# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    module Asterisk
      module AMI
        describe Action do
          it 'registers itself' do
            RayoNode.class_from_registration(:action, 'urn:xmpp:rayo:asterisk:ami:1').should be == Action
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

            subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Action }

            it_should_behave_like 'event'

            its(:name)    { should be == 'Originate' }
            its(:params)  { should be == [Action::Param.new('Channel', 'SIP/101test'),
                                      Action::Param.new('Context', 'default'),
                                      Action::Param.new('Exten', '8135551212'),
                                      Action::Param.new('Priority', '1'),
                                      Action::Param.new('Callerid', '3125551212'),
                                      Action::Param.new('Timeout', '30000'),
                                      Action::Param.new('Variable', 'var1=23|var2=24|var3=25'),
                                      Action::Param.new('Async', '1')
                                     ]}

            its(:params_hash) { should be == {:channel   => 'SIP/101test',
                                           :context   => 'default',
                                           :exten     => '8135551212',
                                           :priority  => '1',
                                           :callerid  => '3125551212',
                                           :timeout   => '30000',
                                           :variable  => 'var1=23|var2=24|var3=25',
                                           :async     => '1'} }
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
              Action.new :name => 'Originate',
                         :params => { :channel => 'SIP/101test' }
            end

            its(:name)        { should be == 'Originate' }
            its(:params)      { should be == [Action::Param.new(:channel, 'SIP/101test')]}
            its(:params_hash) { should be == { :channel => 'SIP/101test' } }
          end

          class Action
            describe Param do
              let(:class_name)    { Param }
              let(:element_name)  { 'param' }
              it_should_behave_like 'key_value_pairs'
            end

            class Complete
              describe Success do
                let :stanza do
                  <<-MESSAGE
<complete xmlns="urn:xmpp:rayo:ext:1">
  <success xmlns="urn:xmpp:rayo:asterisk:ami:complete:1">
    <message>Originate successfully queued</message>
    <attribute name="Channel" value="SIP/101-3f3f"/>
    <attribute name="State" value="Ring"/>
  </success>
</complete>
                  MESSAGE
                end

                subject { RayoNode.import(parse_stanza(stanza).root).reason }

                it { should be_instance_of Success }

                its(:name)            { should be == :success }
                its(:message)         { should be == "Originate successfully queued" }
                its(:attributes)      { should be == [Attribute.new('Channel', 'SIP/101-3f3f'), Attribute.new('State', 'Ring')]}
                its(:attributes_hash) { should be == {:channel => 'SIP/101-3f3f', :state => 'Ring'} }

                describe "when setting options in initializer" do
                  subject do
                    Success.new :message => 'Originate successfully queued', :attributes => {:channel => 'SIP/101-3f3f', :state => 'Ring'}
                  end

                  its(:message)         { should be == 'Originate successfully queued' }
                  its(:attributes)      { should be == [Attribute.new(:channel, 'SIP/101-3f3f'), Attribute.new(:state, 'Ring')]}
                  its(:attributes_hash) { should be == {:channel => 'SIP/101-3f3f', :state => 'Ring'} }
                end
              end

              describe Attribute do
                let(:class_name)    { Attribute }
                let(:element_name)  { 'attribute' }
                it_should_behave_like 'key_value_pairs'
              end
            end
          end
        end # Action
      end # AMI
    end # Asterisk
  end # Component
end # Punchblock
