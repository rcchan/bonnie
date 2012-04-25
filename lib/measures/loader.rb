module Measures
  
  # Utility class for working with JSON files and the database
  class Loader
    include Measures::DatabaseAccess
    # Create a new Loader.
    # @param [String] db_name the name of the database to use
    def initialize(db_name = nil,db_host = nil,db_port = nil)
      determine_connection_information(db_name,db_host,db_port)
      @db = get_db
    end
    
    def load(measures)
      
      measure_id = @db['measures'] << measure_def
      bundle_def['measures'] << measure_id
      bundle_id = @db['bundles'] << bundle_def
      measure_def['bundle'] = bundle_id
      @db['measures'].update({"_id" => measure_id}, measure_def)
    end
    
    def drop_measures
      drop_collection('bundles')
      drop_collection('measures')
    end
    
    def drop_collection(collection)
       @db[collection].drop
    end
    
    def load_library_functions
      save_system_js_fn('map_reduce_utils',File.read(File.join('.','lib','assets','javascripts','libraries','map_reduce_utils.js')))
      save_system_js_fn('underscore_min',File.read(File.join('.','lib','assets','javascripts','libraries','underscore_min.js')))
      save_system_js_fn('hqmf_utils',HQMF2JS::Generator::JS.library_functions)
    end
    
    def save_system_js_fn(name, fn)
      
      fn = "function () {\n #{fn} \n }"
      
      @db['system.js'].save(
        {
          "_id" => name,
          "value" => BSON::Code.new(fn)
        }
      )
    end
    
  end
end