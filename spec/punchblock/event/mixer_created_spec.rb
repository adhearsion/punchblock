# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe MixerCreated do
      subject { described_class.new target_mixer_name: 'foobar' }

      its(:target_mixer_name) { should == 'foobar' }
    end
  end
end
