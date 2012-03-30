require 'factory_girl'

# ==========
# = USERS =
# ==========
FactoryGirl.define :user do |u| 
  u.sequence(:email) { |n| "testuser#{n}@test.com"} 
  u.password 'password' 
  u.password_confirmation 'password'
  u.first_name 'first'
  u.last_name 'last'
  u.sequence(:username) { |n| "testuser#{n}"}
  u.admin false
  u.approved true
  u.agree_license true
end

FactoryGirl.define :admin, :parent => :user do |u|
  u.admin true
end

FactoryGirl.define :unapproved_user, :parent => :user do |u|
  u.approved false
end

