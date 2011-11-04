require 'spec_helper'

module Punchblock
  class Event
    module Asterisk
      module AMI
        describe Event do
          it 'registers itself' do
            RayoNode.class_from_registration(:event, 'urn:xmpp:rayo:asterisk:ami:1').should == Event
          end

          describe "from a stanza" do
            let :stanza do
              <<-MESSAGE
<event xmlns="urn:xmpp:rayo:asterisk:ami:1" name="Newchannel">
  <attribute name="Channel" value="SIP/101-3f3f"/>
  <attribute name="State" value="Ring"/>
  <attribute name="Callerid" value="101"/>
  <attribute name="Uniqueid" value="1094154427.10"/>
</event>
              MESSAGE
            end

            subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Event }

            it_should_behave_like 'event'

            its(:name) { should == 'Newchannel' }
            its(:attributes) { should == [Event::Attribute.new(:channel, 'SIP/101-3f3f'), Event::Attribute.new(:state, 'Ring'), Event::Attribute.new(:callerid, '101'), Event::Attribute.new(:uniqueid, '1094154427.10')]}
            its(:attributes_hash) { should == {:channel => 'SIP/101-3f3f', :state => 'Ring', :callerid => '101', :uniqueid => '1094154427.10'} }
          end

          class Event
            describe Attribute do
              it 'will auto-inherit nodes' do
                n = parse_stanza "<attribute name='boo' value='bah' />"
                h = Attribute.new n.root
                h.name.should == :boo
                h.value.should == 'bah'
              end

              it 'has a name attribute' do
                n = Attribute.new :boo, 'bah'
                n.name.should == :boo
                n.name = :foo
                n.name.should == :foo
              end

              it "substitutes - for _ on the name attribute when reading" do
                n = parse_stanza "<attribute name='boo-bah' value='foo' />"
                h = Attribute.new n.root
                h.name.should == :boo_bah
              end

              it "substitutes _ for - on the name attribute when writing" do
                h = Attribute.new :boo_bah, 'foo'
                h.to_xml.should == '<attribute name="boo-bah" value="foo"/>'
              end

              it 'has a value attribute' do
                n = Attribute.new :boo, 'en'
                n.value.should == 'en'
                n.value = 'de'
                n.value.should == 'de'
              end

              it 'can determine equality' do
                a = Attribute.new :boo, 'bah'
                a.should == Attribute.new(:boo, 'bah')
                a.should_not == Attribute.new(:bah, 'bah')
                a.should_not == Attribute.new(:boo, 'boo')
              end
            end
          end
        end
      end
    end
  end
end # Punchblock
