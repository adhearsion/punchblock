# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    module Asterisk
      module AGI
        describe Command do
          it 'registers itself' do
            RayoNode.class_from_registration(:command, 'urn:xmpp:rayo:asterisk:agi:1').should be == Command
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

            its(:name)          { should be == 'GET VARIABLE' }
            its(:params)        { should be == [Command::Param.new('UNIQUEID')] }
            its(:params_array)  { should be == ['UNIQUEID'] }
          end

          describe "when setting options in initializer" do
            subject do
              Command.new :name => 'GET VARIABLE',
                          :params => ['UNIQUEID']
            end

            its(:name)          { should be == 'GET VARIABLE' }
            its(:params)        { should be == [Command::Param.new('UNIQUEID')] }
            its(:params_array)  { should be == ['UNIQUEID'] }
          end

          class Command
            describe Param do
              it 'will auto-inherit nodes' do
                n = parse_stanza "<param value='bah' />"
                h = Param.new n.root
                h.value.should be == 'bah'
              end

              it 'has a value attribute' do
                n = Param.new 'en'
                n.value.should be == 'en'
                n.value = 'de'
                n.value.should be == 'de'
              end

              it 'can determine equality' do
                a = Param.new 'bah'
                a.should be == Param.new('bah')
                a.should_not be == Param.new('boo')
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

              its(:name)    { should be == :success }
              its(:code)    { should be == 200 }
              its(:result)  { should be == 0 }
              its(:data)    { should be == '1187188485.0' }

              describe "when setting options in initializer" do
                subject do
                  Complete::Success.new :code => 200, :result => 0, :data => '1187188485.0'
                end

                its(:code)    { should be == 200 }
                its(:result)  { should be == 0 }
                its(:data)    { should be == '1187188485.0' }
              end
            end
          end
        end # Command
      end # AGI
    end # Asterisk
  end # Component
end # Punchblock
