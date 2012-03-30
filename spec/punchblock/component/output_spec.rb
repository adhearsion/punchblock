# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe Output do
      it 'registers itself' do
        RayoNode.class_from_registration(:output, 'urn:xmpp:rayo:output:1').should be == Output
      end

      describe 'default values' do
        its(:interrupt_on)     { should be nil }
        its(:start_offset)     { should be nil }
        its(:start_paused)     { should be false }
        its(:repeat_interval)  { should be nil }
        its(:repeat_times)     { should be nil }
        its(:max_time)         { should be nil }
        its(:voice)            { should be nil }
      end

      describe "when setting options in initializer" do
        subject do
          Output.new  :interrupt_on     => :speech,
                      :start_offset     => 2000,
                      :start_paused     => false,
                      :repeat_interval  => 2000,
                      :repeat_times     => 10,
                      :max_time         => 30000,
                      :voice            => 'allison'
        end

        its(:interrupt_on)     { should be == :speech }
        its(:start_offset)     { should be == 2000 }
        its(:start_paused)     { should be == false }
        its(:repeat_interval)  { should be == 2000 }
        its(:repeat_times)     { should be == 10 }
        its(:max_time)         { should be == 30000 }
        its(:voice)            { should be == 'allison' }
      end

      describe "from a stanza" do
        let :stanza do
          <<-MESSAGE
<output xmlns='urn:xmpp:rayo:output:1'
        interrupt-on='speech'
        start-offset='2000'
        start-paused='false'
        repeat-interval='2000'
        repeat-times='10'
        max-time='30000'
        voice='allison'>Hello world</output>
          MESSAGE
        end

        subject { RayoNode.import parse_stanza(stanza).root, '9f00061', '1' }

        it { should be_instance_of Output }

        its(:interrupt_on)     { should be == :speech }
        its(:start_offset)     { should be == 2000 }
        its(:start_paused)     { should be == false }
        its(:repeat_interval)  { should be == 2000 }
        its(:repeat_times)     { should be == 10 }
        its(:max_time)         { should be == 30000 }
        its(:voice)            { should be == 'allison' }
        its(:text)             { should be == 'Hello world' }
      end

      describe "for text" do
        subject { Output.new :text => 'Once upon a time there was a message...', :voice => 'kate' }

        its(:voice) { should be == 'kate' }
        its(:text) { should be == 'Once upon a time there was a message...' }
      end

      describe "for SSML" do
        def ssml_doc(mode = :ordinal)
          RubySpeech::SSML.draw do
            say_as(:interpret_as => mode) { 100 }
          end
        end

        subject { Output.new :ssml => ssml_doc, :voice => 'kate' }

        its(:voice) { should be == 'kate' }

        its(:ssml) { should be == ssml_doc }

        describe "comparison" do
          let(:output2) { Output.new :ssml => '<speak xmlns="http://www.w3.org/2001/10/synthesis" version="1.0" xml:lang="en-US"><say-as interpret-as="ordinal"/></speak>', :voice => 'kate'  }
          let(:output3) { Output.new :ssml => ssml_doc, :voice => 'kate'  }
          let(:output4) { Output.new :ssml => ssml_doc(:normal), :voice => 'kate'  }

          it { should be == output2 }
          it { should be == output3 }
          it { should_not be == output4 }
        end
      end

      describe "actions" do
        let(:mock_client) { mock 'Client' }
        let(:command) { Output.new :text => 'Once upon a time there was a message...', :voice => 'kate' }

        before do
          command.component_id = 'abc123'
          command.target_call_id = '123abc'
          command.client = mock_client
        end

        describe '#pause_action' do
          subject { command.pause_action }

          its(:to_xml) { should be == '<pause xmlns="urn:xmpp:rayo:output:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:target_call_id) { should be == '123abc' }
        end

        describe '#pause!' do
          describe "when the command is executing" do
            before do
              command.request!
              command.execute!
            end

            it "should send its command properly" do
              mock_client.expects(:execute_command).with(command.pause_action, :target_call_id => '123abc', :component_id => 'abc123').returns true
              command.expects :paused!
              command.pause!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.pause! }.should raise_error(InvalidActionError, "Cannot pause a Output that is not executing")
            end
          end
        end

        describe "#paused!" do
          before do
            subject.request!
            subject.execute!
            subject.paused!
          end

          its(:state_name) { should be == :paused }

          it "should raise a StateMachine::InvalidTransition when received a second time" do
            lambda { subject.paused! }.should raise_error(StateMachine::InvalidTransition)
          end
        end

        describe '#resume_action' do
          subject { command.resume_action }

          its(:to_xml) { should be == '<resume xmlns="urn:xmpp:rayo:output:1"/>' }
          its(:component_id) { should be == 'abc123' }
          its(:target_call_id) { should be == '123abc' }
        end

        describe '#resume!' do
          describe "when the command is paused" do
            before do
              command.request!
              command.execute!
              command.paused!
            end

            it "should send its command properly" do
              mock_client.expects(:execute_command).with(command.resume_action, :target_call_id => '123abc', :component_id => 'abc123').returns true
              command.expects :resumed!
              command.resume!
            end
          end

          describe "when the command is not paused" do
            it "should raise an error" do
              lambda { command.resume! }.should raise_error(InvalidActionError, "Cannot resume a Output that is not paused.")
            end
          end
        end

        describe "#resumed!" do
          before do
            subject.request!
            subject.execute!
            subject.paused!
            subject.resumed!
          end

          its(:state_name) { should be == :executing }

          it "should raise a StateMachine::InvalidTransition when received a second time" do
            lambda { subject.resumed! }.should raise_error(StateMachine::InvalidTransition)
          end
        end

        describe '#stop_action' do
          subject { command.stop_action }

          its(:to_xml) { should be == '<stop xmlns="urn:xmpp:rayo:1"/>' }
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
              mock_client.expects(:execute_command).with(command.stop_action, :target_call_id => '123abc', :component_id => 'abc123')
              command.stop!
            end
          end

          describe "when the command is not executing" do
            it "should raise an error" do
              lambda { command.stop! }.should raise_error(InvalidActionError, "Cannot stop a Output that is not executing")
            end
          end
        end # #stop!

        describe "seeking" do
          let(:seek_options) { {:direction => :forward, :amount => 1500} }

          describe '#seek_action' do
            subject { command.seek_action seek_options }

            its(:to_xml) { should be == '<seek xmlns="urn:xmpp:rayo:output:1" direction="forward" amount="1500"/>' }
            its(:component_id) { should be == 'abc123' }
            its(:target_call_id) { should be == '123abc' }
          end

          describe '#seek!' do
            describe "when not seeking" do
              before do
                command.request!
                command.execute!
              end

              it "should send its command properly" do
                seek_action = command.seek_action seek_options
                command.stubs(:seek_action).returns seek_action
                mock_client.expects(:execute_command).with(seek_action, :target_call_id => '123abc', :component_id => 'abc123').returns true
                command.expects :seeking!
                command.expects :stopped_seeking!
                command.seek! seek_options
                seek_action.request!
                seek_action.execute!
              end
            end

            describe "when seeking" do
              before { command.seeking! }

              it "should raise an error" do
                lambda { command.seek! }.should raise_error(InvalidActionError, "Cannot seek an Output that is already seeking.")
              end
            end
          end

          describe "#seeking!" do
            before do
              subject.request!
              subject.execute!
              subject.seeking!
            end

            its(:seek_status_name) { should be == :seeking }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.seeking! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe "#stopped_seeking!" do
            before do
              subject.request!
              subject.execute!
              subject.seeking!
              subject.stopped_seeking!
            end

            its(:seek_status_name) { should be == :not_seeking }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.stopped_seeking! }.should raise_error(StateMachine::InvalidTransition)
            end
          end
        end

        describe "adjusting speed" do
          describe '#speed_up_action' do
            subject { command.speed_up_action }

            its(:to_xml) { should be == '<speed-up xmlns="urn:xmpp:rayo:output:1"/>' }
            its(:component_id) { should be == 'abc123' }
            its(:target_call_id) { should be == '123abc' }
          end

          describe '#speed_up!' do
            describe "when not altering speed" do
              before do
                command.request!
                command.execute!
              end

              it "should send its command properly" do
                speed_up_action = command.speed_up_action
                command.stubs(:speed_up_action).returns speed_up_action
                mock_client.expects(:execute_command).with(speed_up_action, :target_call_id => '123abc', :component_id => 'abc123').returns true
                command.expects :speeding_up!
                command.expects :stopped_speeding!
                command.speed_up!
                speed_up_action.request!
                speed_up_action.execute!
              end
            end

            describe "when speeding up" do
              before { command.speeding_up! }

              it "should raise an error" do
                lambda { command.speed_up! }.should raise_error(InvalidActionError, "Cannot speed up an Output that is already speeding.")
              end
            end

            describe "when slowing down" do
              before { command.slowing_down! }

              it "should raise an error" do
                lambda { command.speed_up! }.should raise_error(InvalidActionError, "Cannot speed up an Output that is already speeding.")
              end
            end
          end

          describe "#speeding_up!" do
            before do
              subject.request!
              subject.execute!
              subject.speeding_up!
            end

            its(:speed_status_name) { should be == :speeding_up }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.speeding_up! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe '#slow_down_action' do
            subject { command.slow_down_action }

            its(:to_xml) { should be == '<speed-down xmlns="urn:xmpp:rayo:output:1"/>' }
            its(:component_id) { should be == 'abc123' }
            its(:target_call_id) { should be == '123abc' }
          end

          describe '#slow_down!' do
            describe "when not altering speed" do
              before do
                command.request!
                command.execute!
              end

              it "should send its command properly" do
                slow_down_action = command.slow_down_action
                command.stubs(:slow_down_action).returns slow_down_action
                mock_client.expects(:execute_command).with(slow_down_action, :target_call_id => '123abc', :component_id => 'abc123').returns true
                command.expects :slowing_down!
                command.expects :stopped_speeding!
                command.slow_down!
                slow_down_action.request!
                slow_down_action.execute!
              end
            end

            describe "when speeding up" do
              before { command.speeding_up! }

              it "should raise an error" do
                lambda { command.slow_down! }.should raise_error(InvalidActionError, "Cannot slow down an Output that is already speeding.")
              end
            end

            describe "when slowing down" do
              before { command.slowing_down! }

              it "should raise an error" do
                lambda { command.slow_down! }.should raise_error(InvalidActionError, "Cannot slow down an Output that is already speeding.")
              end
            end
          end

          describe "#slowing_down!" do
            before do
              subject.request!
              subject.execute!
              subject.slowing_down!
            end

            its(:speed_status_name) { should be == :slowing_down }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.slowing_down! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe "#stopped_speeding!" do
            before do
              subject.request!
              subject.execute!
              subject.speeding_up!
              subject.stopped_speeding!
            end

            its(:speed_status_name) { should be == :not_speeding }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.stopped_speeding! }.should raise_error(StateMachine::InvalidTransition)
            end
          end
        end

        describe "adjusting volume" do
          describe '#volume_up_action' do
            subject { command.volume_up_action }

            its(:to_xml) { should be == '<volume-up xmlns="urn:xmpp:rayo:output:1"/>' }
            its(:component_id) { should be == 'abc123' }
            its(:target_call_id) { should be == '123abc' }
          end

          describe '#volume_up!' do
            describe "when not altering volume" do
              before do
                command.request!
                command.execute!
              end

              it "should send its command properly" do
                volume_up_action = command.volume_up_action
                command.stubs(:volume_up_action).returns volume_up_action
                mock_client.expects(:execute_command).with(volume_up_action, :target_call_id => '123abc', :component_id => 'abc123').returns true
                command.expects :voluming_up!
                command.expects :stopped_voluming!
                command.volume_up!
                volume_up_action.request!
                volume_up_action.execute!
              end
            end

            describe "when voluming up" do
              before { command.voluming_up! }

              it "should raise an error" do
                lambda { command.volume_up! }.should raise_error(InvalidActionError, "Cannot volume up an Output that is already voluming.")
              end
            end

            describe "when voluming down" do
              before { command.voluming_down! }

              it "should raise an error" do
                lambda { command.volume_up! }.should raise_error(InvalidActionError, "Cannot volume up an Output that is already voluming.")
              end
            end
          end

          describe "#voluming_up!" do
            before do
              subject.request!
              subject.execute!
              subject.voluming_up!
            end

            its(:volume_status_name) { should be == :voluming_up }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.voluming_up! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe '#volume_down_action' do
            subject { command.volume_down_action }

            its(:to_xml) { should be == '<volume-down xmlns="urn:xmpp:rayo:output:1"/>' }
            its(:component_id) { should be == 'abc123' }
            its(:target_call_id) { should be == '123abc' }
          end

          describe '#volume_down!' do
            describe "when not altering volume" do
              before do
                command.request!
                command.execute!
              end

              it "should send its command properly" do
                volume_down_action = command.volume_down_action
                command.stubs(:volume_down_action).returns volume_down_action
                mock_client.expects(:execute_command).with(volume_down_action, :target_call_id => '123abc', :component_id => 'abc123').returns true
                command.expects :voluming_down!
                command.expects :stopped_voluming!
                command.volume_down!
                volume_down_action.request!
                volume_down_action.execute!
              end
            end

            describe "when voluming up" do
              before { command.voluming_up! }

              it "should raise an error" do
                lambda { command.volume_down! }.should raise_error(InvalidActionError, "Cannot volume down an Output that is already voluming.")
              end
            end

            describe "when voluming down" do
              before { command.voluming_down! }

              it "should raise an error" do
                lambda { command.volume_down! }.should raise_error(InvalidActionError, "Cannot volume down an Output that is already voluming.")
              end
            end
          end

          describe "#voluming_down!" do
            before do
              subject.request!
              subject.execute!
              subject.voluming_down!
            end

            its(:volume_status_name) { should be == :voluming_down }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.voluming_down! }.should raise_error(StateMachine::InvalidTransition)
            end
          end

          describe "#stopped_voluming!" do
            before do
              subject.request!
              subject.execute!
              subject.voluming_up!
              subject.stopped_voluming!
            end

            its(:volume_status_name) { should be == :not_voluming }

            it "should raise a StateMachine::InvalidTransition when received a second time" do
              lambda { subject.stopped_voluming! }.should raise_error(StateMachine::InvalidTransition)
            end
          end
        end
      end
    end

    describe Output::Complete::Success do
      let :stanza do
        <<-MESSAGE
<complete xmlns='urn:xmpp:rayo:ext:1'>
<success xmlns='urn:xmpp:rayo:output:complete:1' />
</complete>
        MESSAGE
      end

      subject { RayoNode.import(parse_stanza(stanza).root).reason }

      it { should be_instance_of Output::Complete::Success }

      its(:name) { should be == :success }
    end
  end
end # Punchblock
