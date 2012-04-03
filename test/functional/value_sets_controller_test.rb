require 'test_helper'

class ValueSetsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
  setup do
    dump_database
    @vs = FactoryGirl.build(:value_set)
    @user = FactoryGirl.create(:user)
    sign_in @user
  end
  
  test "index" do
    get :index
    
    assert_response :success
    assert_template :index
    refute_nil assigns(:value_sets)
  end
  
  test "new value set" do
    get :new
    
    assert_response :success
    refute_nil assigns(:value_set)
  end
  
  test "destroy value set" do
    assert @vs.save
    delete :destroy, id: @vs.id
    assert assigns(:value_set).destroyed?
    assert_response 302
    assert_redirected_to value_sets_path
  end
  
  test "should not create invalid value set" do
    post :create, value_set: {category: "foobar"}
    
    assert_response 406
    assert_template :new
    refute_nil assigns(:value_set)
    refute_nil flash[:error]
    assert !assigns(:value_set).valid?
  end
  
  test "create" do
    post :create, value_set: {category: @vs.category, oid: @vs.oid}
    
    @vs = ValueSet.first
    refute_nil @vs
    assert_response 302
    assert_redirected_to value_set_path(@vs)
    refute_nil assigns(:value_set)
    assert(assigns(:value_set).persisted?)
  end
  
  test "update" do
    assert @vs.save
    @vs2 = FactoryGirl.build(:value_set)
    
    put :update, id: @vs.id, value_set: {category: @vs2.category}
    
    @vs.reload
    assert_equal @vs2.category, @vs.category
  end
  
  test "show" do
    assert @vs.save
    
    get :show, id: @vs.id
    
    assert_response :success
    assert_template :show
  end
end
