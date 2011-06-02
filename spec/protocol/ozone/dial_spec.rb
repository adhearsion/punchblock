require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Dial do
        subject { Dial.new :to => 'tel:+14155551212', :from => 'tel:+13035551212' }

        its(:to_xml) { should == '<dial xmlns="urn:xmpp:ozone:1" to="tel:+14155551212" from="tel:+13035551212"/>' }
      end
    end # Ozone
  end # Protocol
end # Punchblock
