require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Audio do
        describe "for audio" do
          subject { Audio.new 'http://whatever.you-say-boss.com' }

          its(:node_name) { should == 'audio' }
          its(:src) { should == 'http://whatever.you-say-boss.com' }
        end
      end
    end # Ozone
  end # Protocol
end # Punchblock
