require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      module Component
        module Asterisk
          class Input
            describe DTMFMatcher do

              let :grammar do
                RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'digit' do
                  rule id: 'digit' do
                    one_of do
                      0.upto(9) { |d| item { d.to_s } }
                    end
                  end
                end
              end

              subject { DTMFMatcher.new grammar }

              its(:grammar) { should be grammar }

              it "should be able to identify its root rule" do
                subject.root_rule.id.should == :digit
              end

              describe "with a non-dtmf grammar" do
                let :grammar do
                  RubySpeech::GRXML.draw :mode => 'speech', :root => 'name' do
                    rule id: 'name' do
                      one_of do
                        item { "Frank" }
                        item { "Jim" }
                        item { "Paul" }
                      end
                    end
                  end
                end

                it "should raise an argument error" do
                  lambda { DTMFMatcher.new grammar }.should raise_error ArgumentError, /DTMF grammar/
                end
              end

              describe "with a simple single-digit grammar" do
                it "should initially not have a match" do
                  subject.match?.should be nil
                end

                it "should match on the first digit" do
                  subject << '5'
                  subject.match?.should be true
                  subject.invalid.should be_false
                end

                it "should be invalid with a #" do
                  subject << '#'
                  subject.match?.should be false
                  subject.invalid?.should be_true
                end

                it "should be invalid a *" do
                  subject << '*'
                  subject.match?.should be false
                  subject.invalid?.should be_true
                end
              end

              describe "with a simple two-digit PIN grammar, terminated by #" do
                let :grammar do
                  RubySpeech::GRXML.draw :mode => 'dtmf', :root => 'pin' do
                    rule id: 'digit' do
                      one_of do
                        0.upto(9) { |d| item { d.to_s } }
                      end
                    end

                    rule id: 'pin', scope: 'public' do
                      one_of do
                        item do
                          item repeat: '2' do
                            ruleref uri: '#digit'
                          end
                          "#"
                        end
                      end
                    end
                  end
                end

              end
            end
          end
        end
      end
    end
  end
end
