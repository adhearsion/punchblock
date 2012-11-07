# encoding: utf-8

require 'spec_helper'

module Punchblock
  describe Header do
    let(:element_name) { 'header' }

    it_should_behave_like 'key_value_pairs'
  end
end # Punchblock
