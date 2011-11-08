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

            its(:name)            { should == 'Newchannel' }
            its(:attributes)      { should == [Event::Attribute.new(:channel, 'SIP/101-3f3f'), Event::Attribute.new(:state, 'Ring'), Event::Attribute.new(:callerid, '101'), Event::Attribute.new(:uniqueid, '1094154427.10')]}
            its(:attributes_hash) { should == {:channel => 'SIP/101-3f3f', :state => 'Ring', :callerid => '101', :uniqueid => '1094154427.10'} }
          end

          describe "when setting options in initializer" do
            subject do
              Event.new :name => 'Newchannel',
                        :attributes => {:channel  => 'SIP/101-3f3f',
                                        :state    => 'Ring',
                                        :callerid => '101',
                                        :uniqueid => '1094154427.10'}
            end

            its(:name)            { should == 'Newchannel' }
            its(:attributes)      { should == [Event::Attribute.new(:channel, 'SIP/101-3f3f'), Event::Attribute.new(:state, 'Ring'), Event::Attribute.new(:callerid, '101'), Event::Attribute.new(:uniqueid, '1094154427.10')]}
            its(:attributes_hash) { should == {:channel => 'SIP/101-3f3f', :state => 'Ring', :callerid => '101', :uniqueid => '1094154427.10'} }
          end

          class Event
            describe Attribute do
              let(:class_name)    { Attribute }
              let(:element_name)  { 'attribute' }
              it_should_behave_like 'key_value_pairs'
            end
          end
        end
      end
    end
  end
end # Punchblock
