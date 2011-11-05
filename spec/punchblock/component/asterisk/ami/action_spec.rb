require 'spec_helper'

module Punchblock
  module Component
    module Asterisk
      module AMI
        describe Action do
          it 'registers itself' do
            RayoNode.class_from_registration(:action, 'urn:xmpp:rayo:asterisk:ami:1').should == Action
          end

#           describe "from a stanza" do
#             let :stanza do
#               <<-MESSAGE
# <event xmlns="urn:xmpp:rayo:asterisk:ami:1" name="Newchannel">
#   <attribute name="Channel" value="SIP/101-3f3f"/>
#   <attribute name="State" value="Ring"/>
#   <attribute name="Callerid" value="101"/>
#   <attribute name="Uniqueid" value="1094154427.10"/>
# </event>
#               MESSAGE
#             end

 
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

            its(:name) { should == 'Originate' }
            its(:params) { should == [Action::Param.new(:channel, 'SIP/101test'),
                                     Action::Param.new(:context, 'default'),
                                     Action::Param.new(:exten, '8135551212'),
                                     Action::Param.new(:priority, '1'),
                                     Action::Param.new(:callerid, '3125551212'),
                                     Action::Param.new(:timeout, '30000'),
                                     Action::Param.new(:variable, 'var1=23|var2=24|var3=25'),
                                     Action::Param.new(:async, '1')
                                     ]}

            its(:params_hash) { should == {:channel => 'SIP/101test',
                                           :context => 'default',
                                           :exten => '8135551212',
                                           :priority => '1',
                                           :callerid => '3125551212',
                                           :timeout => '30000',
                                           :variable => 'var1=23|var2=24|var3=25',
                                           :async => '1'} }
          end


          class Action
            describe Param do
              it 'will auto-inherit nodes' do
                n = parse_stanza "<param name='boo' value='bah' />"
                h = Param.new n.root
                h.name.should == :boo
                h.value.should == 'bah'
              end

              it 'has a name attribute' do
                n = Param.new :boo, 'bah'
                n.name.should == :boo
                n.name = :foo
                n.name.should == :foo
              end

              it "substitutes - for _ on the name attribute when reading" do
                n = parse_stanza "<param name='boo-bah' value='foo' />"
                h = Param.new n.root
                h.name.should == :boo_bah
              end

              it "substitutes _ for - on the name attribute when writing" do
                h = Param.new :boo_bah, 'foo'
                h.to_xml.should == '<param name="boo-bah" value="foo"/>'
              end

              it 'has a value param' do
                n = Param.new :boo, 'en'
                n.value.should == 'en'
                n.value = 'de'
                n.value.should == 'de'
              end

              it 'can determine equality' do
                pending "It's broken"
                a = Param.new :boo, 'bah'
                a.should == Param.new(:boo, 'bah')
                a.should_not == Param.new(:bah, 'bah')
                a.should_not == Param.new(:boo, 'boo')
              end
            end
          end
         end # Action
      end #  AMI
    end # Asterisk
  end # Component
end # Punchblock
