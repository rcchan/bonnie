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
  
  test "model method should allow for easy selection of population criteria in the measure" do
    population_criterias = { 
  		NUMER:    { population: 1 },
  		NUMER_1:  { population: 2 },
  		NUMER_2:  { population: 3 },
  		DENOM:    { population: 1 },
  		DENOM_1:  { population: 2 },
  		DENOM_2:  { population: 3 },
  		EXCL:     { population: 1 },
  		EXCL_1:   { population: 2 },
  		EXCL_2:   { population: 3 }
    }
    
    @measure.population_criteria = population_criterias
    @measure.save

    first = Measure.where(_id:"#{Measure.first.id}").only_population(1).first
    assert_equal ["NUMER", "DENOM", "EXCL"].sort, first.population_criteria.keys.sort
    
    second = Measure.where(_id:"#{Measure.first.id}").only_population(2).first
    assert_equal ["NUMER_1", "DENOM_1", "EXCL_1"].sort, second.population_criteria.keys.sort

    third = Measure.where(_id:"#{Measure.first.id}").only_population(3).first
    assert_equal ["NUMER_2", "DENOM_2", "EXCL_2"].sort, third.population_criteria.keys.sort
  end
  
end
