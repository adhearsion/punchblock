require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Answer do
        its(:to_xml) { should == '<answer xmlns="urn:xmpp:ozone:1"/>' }
      end
    end
  end
end
