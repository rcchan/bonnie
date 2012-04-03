require 'factory_girl'

FactoryGirl.define do

  # ==========
  # = USERS =
  # ==========
  

  factory :user do |u| 
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

  factory :admin, :parent => :user do |u|
    u.admin true
  end

  factory :unapproved_user, :parent => :user do |u|
    u.approved false
  end

  factory :measure do |m| 
    m.sequence(:nqf_id) { |n| "00#{n}" }
    m.sequence(:title)  { |n| "Measure #{n}" }
    m.sequence(:description)  { |n| "This is the description for measure #{n}" }
  end
  
end


