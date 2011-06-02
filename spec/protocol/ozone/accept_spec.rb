require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Accept do
        its(:to_xml) { should == '<accept xmlns="urn:xmpp:ozone:1"/>' }
      end
    end # Ozone
  end # Protocol
end # Punchblock
