require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  setup do
    dump_database
    @user = FactoryGirl.create(:user)
  end
  
  test "user should be found by username" do
    found_user = User.by_username @user.username
    assert_equal @user, found_user
  end

  test "user should be found by email" do
    found_user = User.by_email @user.email
    assert_equal @user, found_user
  end
  
  test "fullname should return proper value" do
    @user.full_name.must_equal "first last"
  end
  
end
