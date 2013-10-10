# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Client
    describe ComponentRegistry do
      let(:uri)       { 'abc123' }
      let(:component) { double 'Component', uri: uri }

      it 'should store components and allow lookup by ID' do
        subject << component
        subject.find_by_uri(uri).should be component
      end

      it 'should allow deletion of components' do
        subject << component
        subject.find_by_uri(uri).should be component
        subject.delete component
        subject.find_by_uri(uri).should be_nil
      end
    end
  end
end
