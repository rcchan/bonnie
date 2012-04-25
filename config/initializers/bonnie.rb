APP_CONFIG = YAML.load_file(Rails.root.join('config', 'bonnie.yml'))[Rails.env]

Dir[Rails.root + 'lib/**/*.rb'].each do |file|
  require file
end