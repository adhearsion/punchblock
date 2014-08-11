# encoding: utf-8

require 'spec_helper'

describe Punchblock::URIList do
  describe '#size' do
    subject { super().size }
    it { should == 0 }
  end

  context "created with a set of entries" do
    subject { described_class.new 'http://example.com/hello.mp3', 'http://example.com/goodbye.mp3' }

    describe '#size' do
      subject { super().size }
      it { should == 2 }
    end

    describe '#to_ary' do
      subject { super().to_ary }
      it { should == ['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3'] }
    end

    describe '#to_s' do
      subject { super().to_s }
      it { should == "http://example.com/hello.mp3\nhttp://example.com/goodbye.mp3" }
    end
  end

  context "created with an array of entries" do
    subject { described_class.new ['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3'] }

    describe '#size' do
      subject { super().size }
      it { should == 2 }
    end

    describe '#to_ary' do
      subject { super().to_ary }
      it { should == ['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3'] }
    end

    describe '#to_s' do
      subject { super().to_s }
      it { should == "http://example.com/hello.mp3\nhttp://example.com/goodbye.mp3" }
    end
  end

  context "imported from a string" do
    let(:string) do
      <<-STRING
      http://example.com/hello.mp3
      http://example.com/goodbye.mp3
      STRING
    end

    subject { described_class.import string }

    describe '#size' do
      subject { super().size }
      it { should == 2 }
    end

    describe '#to_ary' do
      subject { super().to_ary }
      it { should == ['http://example.com/hello.mp3', 'http://example.com/goodbye.mp3'] }
    end

    describe '#to_s' do
      subject { super().to_s }
      it { should == "http://example.com/hello.mp3\nhttp://example.com/goodbye.mp3" }
    end
  end

  describe "comparisons" do
    context "when the elements are the same" do
      described_class.new('foo', 'bar').should == described_class.new('foo', 'bar')
    end

    context "when the elements are different" do
      described_class.new('foo', 'baz').should_not == described_class.new('bar', 'baz')
    end
  end
end
