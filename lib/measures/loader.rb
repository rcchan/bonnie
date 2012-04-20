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
      
    end
    
    def drop_measures
      binding.pry
      drop_collection('bundles')
      drop_collection('measures')
    end
    
    def drop_collection(collection)
       @db[collection].drop
    end
    
    
    
  end
end