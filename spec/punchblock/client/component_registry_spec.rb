# encoding: utf-8

require 'spec_helper'

module Punchblock
  class Client
    describe ComponentRegistry do
      let(:component_id)  { 'abc123' }
      let(:component)     { stub 'Component', :component_id => component_id }

      it 'should store components and allow lookup by ID' do
        subject << component
        subject.find_by_id(component_id).should be component
      end

      it 'should allow deletion of components' do
        subject << component
        subject.find_by_id(component_id).should be component
        subject.delete component
        subject.find_by_id(component_id).should be_nil
      end
    end
  end
end
