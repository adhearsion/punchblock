require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Redirect do
        subject { Redirect.new 'tel:+14045551234' }

        its(:to_xml) { should == '<redirect xmlns="urn:xmpp:ozone:1" to="tel:+14045551234"/>' }
      end
    end
  end
end
