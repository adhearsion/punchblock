# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Header do
    it 'will auto-inherit nodes' do
      n = parse_stanza "<header name='boo' value='bah' />"
      h = Header.new n.root
      h.name.should be == :boo
      h.value.should be == 'bah'
    end

    it 'has a name attribute' do
      n = Header.new :boo, 'bah'
      n.name.should be == :boo
      n.name = :foo
      n.name.should be == :foo
    end

    it "substitutes - for _ on the name attribute when reading" do
      n = parse_stanza "<header name='boo-bah' value='foo' />"
      h = Header.new n.root
      h.name.should be == :boo_bah
    end

    it "substitutes _ for - on the name attribute when writing" do
      h = Header.new :boo_bah, 'foo'
      h.to_xml.should be == '<header name="boo-bah" value="foo"/>'
    end

    it 'has a value attribute' do
      n = Header.new :boo, 'en'
      n.value.should be == 'en'
      n.value = 'de'
      n.value.should be == 'de'
    end

    it 'can determine equality' do
      a = Header.new :boo, 'bah'
      a.should be == Header.new(:boo, 'bah')
      a.should_not be == Header.new(:bah, 'bah')
      a.should_not be == Header.new(:boo, 'boo')
    end
  end
end # Punchblock
