require 'spec_helper'

module Punchblock
  module Component
    module Asterisk
      module AMI
        describe Action do
          it 'registers itself' do
            RayoNode.class_from_registration(:action, 'urn:xmpp:rayo:asterisk:ami:1').should == Action
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

            its(:name)    { should == 'Originate' }
            its(:params)  { should == [Action::Param.new(:channel, 'SIP/101test'),
                                      Action::Param.new(:context, 'default'),
                                      Action::Param.new(:exten, '8135551212'),
                                      Action::Param.new(:priority, '1'),
                                      Action::Param.new(:callerid, '3125551212'),
                                      Action::Param.new(:timeout, '30000'),
                                      Action::Param.new(:variable, 'var1=23|var2=24|var3=25'),
                                      Action::Param.new(:async, '1')
                                     ]}

            its(:params_hash) { should == {:channel   => 'SIP/101test',
                                           :context   => 'default',
                                           :exten     => '8135551212',
                                           :priority  => '1',
                                           :callerid  => '3125551212',
                                           :timeout   => '30000',
                                           :variable  => 'var1=23|var2=24|var3=25',
                                           :async     => '1'} }
          end

          describe "when setting options in initializer" do
            subject do
              Action.new :name => 'Originate',
                         :params => { :channel => 'SIP/101test' }
            end

            its(:name)        { should == 'Originate' }
            its(:params)      { should == [Action::Param.new(:channel, 'SIP/101test')]}
            its(:params_hash) { should == { :channel => 'SIP/101test' } }
          end

          class Action
            describe Param do
              let(:class_name)    { Param }
              let(:element_name)  { 'param' }
              it_should_behave_like 'key_value_pairs'
            end

            describe Complete::Success do
              let :stanza do
                <<-MESSAGE
<complete xmlns="urn:xmpp:rayo:ext:1">
  <success xmlns="urn:xmpp:rayo:asterisk:ami:complete:1">
    <message>Originate successfully queued</message>
  </success>
</complete>
                MESSAGE
              end

              subject { RayoNode.import(parse_stanza(stanza).root).reason }

              it { should be_instance_of Complete::Success }

              its(:name)    { should == :success }
              its(:message) { should == "Originate successfully queued" }

              describe "when setting options in initializer" do
                subject do
                  Complete::Success.new :message => 'Originate successfully queued'
                end

                its(:message) { should == 'Originate successfully queued' }
              end
            end
          end
        end # Action
      end # AMI
    end # Asterisk
  end # Component
end # Punchblock
