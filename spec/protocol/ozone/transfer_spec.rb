require 'spec_helper'

module Punchblock
  module Protocol
    module Ozone
      describe Transfer do
        subject do
          Transfer.new 'tel:+14045551212', :from            => 'tel:+14155551212',
                                           :terminator      => '*',
                                           :timeout         => 120000,
                                           :answer_on_media => 'true'
        end

        its(:to_xml) { should == '<transfer xmlns="urn:xmpp:ozone:transfer:1" from="tel:+14155551212" terminator="*" timeout="120000" answer-on-media="true" to="tel:+14045551212"/>' }
      end
    end
  end
end
