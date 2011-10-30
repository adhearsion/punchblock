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
    end
  end
end
