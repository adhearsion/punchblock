require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Hangup do
        its(:to_xml) { should == '<hangup xmlns="urn:xmpp:ozone:1"/>' }
      end
    end # Ozone
  end # Protocol
end # Punchblock
