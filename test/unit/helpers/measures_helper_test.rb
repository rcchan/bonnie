require 'test_helper'

class MeasuresHelperTest < ActionView::TestCase
  class DummyClass < ActionView::Base
    include MeasuresHelper
  end
  
  # helper creates a javascript string from a measure number
  # test "javascript include for measure debug view" do
  #   dc = DummyClass.new
  #   assert_equal "", dc.include_js_debug
  # end
  
  
end

