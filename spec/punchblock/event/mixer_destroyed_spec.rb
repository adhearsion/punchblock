# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Event
    describe MixerDestroyed do
      subject { described_class.new target_mixer_name: 'foobar' }

      its(:target_mixer_name) { should == 'foobar' }
    end
  end
end
