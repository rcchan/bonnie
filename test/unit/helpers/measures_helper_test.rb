require 'test_helper'

class MeasuresHelperTest < ActionView::TestCase
  # create a dummy class because modules can't be instantiated directly
  class DummyClass < ActionView::Base
    include MeasuresHelper
  end
  
  # FIXME: I need a Record/Patient factory here - cdillon
  # helper creates a javascript string from a measure number
  # test "javascript include for measure debug view" do
  #   dc = DummyClass.new
  #   binding.pry
  #   js = dc.include_js_debug("0001", ["4fa98071431a5fb25f000002"])
  #   # some simple content tests to see if the generated javascript is at least close
  #   assert_match(Regexp.new('var patient'), js)
  #   assert_match(Regexp.new('hqmfjs.DENOM'), js)
  # end
  
end
