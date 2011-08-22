require 'spec_helper'

module Punchblock
  describe Audio do
    describe "for a URL" do
      subject { Audio.new :url => 'http://whatever.you-say-boss.com' }

      its(:src) { should == 'http://whatever.you-say-boss.com' }
    end

    describe "for text" do
      subject { Audio.new :text => 'Hello' }

      its(:content) { should == 'Hello' }
    end
  end
end # Punchblock
