# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Client
    describe ComponentRegistry do
      let(:component_key)  { 'abc123foo123' }
      let(:component)      { double 'Component', :key => component_key }

      it 'should store components and allow lookup by ID' do
        subject << component
        subject.find_by_key(component_key).should be component
      end

      it 'should allow deletion of components' do
        subject << component
        subject.find_by_key(component_key).should be component
        subject.delete component
        subject.find_by_key(component_key).should be_nil
      end
    end
  end
end
