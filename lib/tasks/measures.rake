require './lib/measures/database_access'
require './lib/measures/loader'

namespace :measures do
  desc 'Remove the measures and bundles collection'
  task :drop_measures do
    loader = Measures::Loader.new()
    loader.drop_measures()
  end

  desc 'Load a set of measures for popHealth'
  task :load, [:measures_dir, :db_name, :db_host, :db_port] do |task, args|
    loader = Measures::Loader.new(args.db_name, args.db_host, args.db_port)
    loader.drop_measures()
    loader.load(args.measures_dir)
    loader.load_library_functions
  end
  
end
