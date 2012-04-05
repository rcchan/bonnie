guard 'spork' do
  watch('config/application.rb')
  watch('config/environment.rb')
  watch(%r{^config/environments/.+\\.rb$})
  watch(%r{^config/initializers/.+\\.rb$})
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('test/test_helper.rb') { :minitest }
  watch(%r{features/support/}) { :cucumber }
end

guard 'minitest' do
  # with Minitest::Unit
  watch(%r|^test/(.*)\/(.*)_test\.rb|)
  watch(%r|^lib/(.*)\.rb|)     { |m| puts "#{m[1]}"; "test/unit/lib/#{m[1]}_test.rb" }
  watch(%r|^test/test_helper\.rb|)    { "test" }

  # Rails 3.2
  watch(%r|^app/controllers/(.*)\.rb|) { |m| "test/functional/#{m[1]}_test.rb" }
  watch(%r|^app/helpers/(.*)\.rb|)     { |m| "test/helpers/#{m[1]}_test.rb" }
  watch(%r|^app/models/(.*)\.rb|)      { |m| "test/unit/#{m[1]}_test.rb" }    
end
