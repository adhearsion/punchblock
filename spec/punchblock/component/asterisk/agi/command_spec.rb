require 'spec_helper'

module Punchblock
  module Component
    module Asterisk
      module AGI
        describe Command do
          it 'registers itself' do
            RayoNode.class_from_registration(:command, 'urn:xmpp:rayo:asterisk:agi:1').should == Command
          end

          describe "from a stanza" do
            let :stanza do
              <<-MESSAGE
<command xmlns="urn:xmpp:rayo:asterisk:agi:1" name="GET VARIABLE">
  <param value="UNIQUEID"/>
</command>
              MESSAGE
            end

            subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

            it { should be_instance_of Command }

            it_should_behave_like 'event'

            its(:name)          { should == 'GET VARIABLE' }
            its(:params)        { should == [Command::Param.new('UNIQUEID')] }
            its(:params_array)  { should == ['UNIQUEID'] }
          end

          describe "when setting options in initializer" do
            subject do
              Command.new :name => 'GET VARIABLE',
                          :params => ['UNIQUEID']
            end

            its(:name)          { should == 'GET VARIABLE' }
            its(:params)        { should == [Command::Param.new('UNIQUEID')] }
            its(:params_array)  { should == ['UNIQUEID'] }
          end

          class Command
            describe Param do
              it 'will auto-inherit nodes' do
                n = parse_stanza "<param value='bah' />"
                h = Param.new n.root
                h.value.should == 'bah'
              end

              it 'has a value attribute' do
                n = Param.new 'en'
                n.value.should == 'en'
                n.value = 'de'
                n.value.should == 'de'
              end

              it 'can determine equality' do
                a = Param.new 'bah'
                a.should == Param.new('bah')
                a.should_not == Param.new('boo')
              end
            end

            describe Complete::Success do
              let :stanza do
                <<-MESSAGE
<complete xmlns="urn:xmpp:rayo:ext:1">
  <success xmlns="urn:xmpp:rayo:asterisk:agi:complete:1">
    <code>200</code>
    <result>0</result>
    <data>1187188485.0</data>
  </success>
</complete>
                MESSAGE
              end

              subject { RayoNode.import(parse_stanza(stanza).root).reason }

              it { should be_instance_of Complete::Success }

              its(:name)    { should == :success }
              its(:code)    { should == 200 }
              its(:result)  { should == 0 }
              its(:data)    { should == '1187188485.0' }

              describe "when setting options in initializer" do
                subject do
                  Complete::Success.new :code => 200, :result => 0, :data => '1187188485.0'
                end

                its(:code)    { should == 200 }
                its(:result)  { should == 0 }
                its(:data)    { should == '1187188485.0' }
              end
            end
          end
        end # Command
      end # AGI
    end # Asterisk
  end # Component
end # Punchblock
