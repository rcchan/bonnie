require 'factory_girl'

FactoryGirl.define do

  factory :value_set do |f|
    f.category { ValueSet::Categories.sample }
    f.oid "2.16.840.1.113883.3.464.0002.1138"
    f.code_set "RxNorm"
    f.concept "Encounters ALL inpatient and ambulatory"
    f.codes { %w(99201 99202 99203 99204 99205) }
  end

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
    m.sequence(:endorser) { |n| "NQF" }
    m.sequence(:measure_id) { |n| "00#{n}" }
    m.sequence(:title)  { |n| "Measure #{n}" }
    m.sequence(:description)  { |n| "This is the description for measure #{n}" }
  end
  
end


