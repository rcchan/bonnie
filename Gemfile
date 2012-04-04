source 'https://rubygems.org'

gem 'rails', '3.2.2'
gem 'jquery-rails'

gem 'pry'

gem 'devise'
gem 'foreman'
gem 'cancan'
gem 'factory_girl'

gem "mongo"
gem "mongoid"
gem "bson"
gem 'bson_ext'

gem 'simple_form'

group :test, :develop do
  # Pretty printed test output
  gem 'turn', :require => false
  gem 'cover_me'
  gem 'minitest'
  gem 'mocha', :require => false
end

group :production do
  gem 'therubyracer', :platforms => [:ruby, :jruby]
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end
