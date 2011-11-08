require 'spec_helper'

module Punchblock
  module Translator
    class Asterisk
      describe Call do
        describe '#register_component' do
          it 'should make the component accessible by ID' do
            component_id = 'abc123'
            component    = mock 'Translator::Asterisk::Component', :id => component_id
            subject.register_component component
            subject.component_with_id(component_id).should be component
          end
        end
      end
    end
  end
end
