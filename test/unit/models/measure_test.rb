require 'test_helper'

class MeasureTest < ActiveSupport::TestCase
  
  setup do
    @measure = FactoryGirl.create(:measure)
  end
  
  teardown do
    Measure.delete_all
  end
  
  test "publish measure should change state properly" do
    assert !@measure.published
    assert_nil @measure.publish_date
    assert_nil @measure.version
    @measure.publish
    assert @measure.published
    assert_not_nil @measure.publish_date
    assert_not_nil @measure.version
    assert_equal 1, @measure.publishings.count
    assert_equal @measure.title, @measure.publishings.by_version(1).first.title
  end

  test "multiple publish measure should change state properly" do
    original_title = @measure.title
    @measure.publish
    assert_equal @measure.title, @measure.publishings.by_version(1).first.title
    @measure.title = "changed title"
    @measure.publish
    assert @measure.published
    assert_not_nil @measure.publish_date
    assert_not_nil @measure.version
    assert_equal 2, @measure.publishings.count
    assert_equal "changed title", @measure.publishings.by_version(2).first.title
  end
  
end
