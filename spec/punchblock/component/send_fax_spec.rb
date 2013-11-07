# encoding: utf-8

require 'spec_helper'

module Punchblock
  module Component
    describe SendFax do
      it 'registers itself' do
        RayoNode.class_from_registration(:sendfax, 'urn:xmpp:rayo:fax:1').should be == described_class
      end

      subject do
        SendFax.new render_documents: [SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff', pages: [1..4,5,7..9])]
      end

      its(:render_documents) { should be == [SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff', pages: [1..4,5,7..9])] }

      describe "exporting to Rayo" do
        it "should export to XML that can be understood by its parser" do
          new_instance = RayoNode.from_xml Nokogiri::XML(subject.to_rayo.to_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).root
          new_instance.render_documents.should be == [SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff', pages: [1..4,5,7..9])]
        end
      end

      context "without optional attributes" do
        subject do
          SendFax.new render_documents: [SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff')]
        end

        describe "exporting to Rayo" do
          it "should export to XML that can be understood by its parser" do
            new_instance = RayoNode.from_xml Nokogiri::XML(subject.to_rayo.to_xml, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS).root
            new_instance.render_documents.should be == [SendFax::FaxDocument.new(url: 'http://example.com/faxes/document.tiff')]
          end
        end
      end

      context "from a rayo stanza" do

        subject { RayoNode.from_xml parse_stanza(stanza).root, '9f00061', '1' }

        let :stanza do
            <<-MESSAGE
<sendfax xmlns='urn:xmpp:rayo:fax:1'>
  <document xmlns='urn:xmpp:rayo:fax:1' url='http://shakespere.lit/my_fax.tiff' identity='+14045555555' header='Hello world' pages='1-4,5,7-9'/>
</sendfax>
            MESSAGE
        end

        its(:render_documents) { should be == [SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9])] }

        context "without optional attributes" do
          let :stanza do
              <<-MESSAGE
<sendfax xmlns='urn:xmpp:rayo:fax:1'>
  <document xmlns='urn:xmpp:rayo:fax:1' url='http://shakespere.lit/my_fax.tiff'/>
</sendfax>
              MESSAGE
          end

          its(:render_documents) { should be == [SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff')] }
        end
      end
    end

    describe SendFax::FaxDocument do
      it "registers itself" do
        RayoNode.class_from_registration(:document, 'urn:xmpp:rayo:fax:1').should be == described_class
      end

      subject { SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9]) }

      its(:url)       { should == 'http://shakespere.lit/my_fax.tiff' }
      its(:identity)  { should == '+14045555555' }
      its(:header)    { should == 'Hello world' }
      its(:pages)     { should == [1..4,5,7..9] }

      context "without optional attributes" do
        subject { SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff') }

        its(:url)       { should == 'http://shakespere.lit/my_fax.tiff' }
        its(:identity)  { should be_nil }
        its(:header)    { should be_nil }
        its(:pages)     { should be_nil }
      end

      describe "comparison" do
        it "should be the same with the same attributes" do
          should be == SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9])
        end

        it "should be different with a different url" do
          should_not be == SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_other_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,7..9])
        end

        it "should be different with a different identity" do
          should_not be == SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555556', header: 'Hello world', pages: [1..4,5,7..9])
        end

        it "should be different with a different header" do
          should_not be == SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello Paul', pages: [1..4,5,7..9])
        end

        it "should be different with a different pages" do
          should_not be == SendFax::FaxDocument.new(url: 'http://shakespere.lit/my_fax.tiff', identity: '+14045555555', header: 'Hello world', pages: [1..4,5,6..9])
        end
      end
    end
  end
end
