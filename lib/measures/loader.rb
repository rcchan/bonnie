require 'JSON'
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
      measures = File.expand_path(File.join('.','test','fixtures','pophealth'))
      measure_def = JSON.parse(File.open(File.join(measures,'0043.json')).read)

      measure_js = File.open(File.expand_path(File.join('.','tmp','measures','NQF_0043.xml.js'))).read
      
      map = "function() {
        var patient = this;
        var effective_date = <%= effective_date %>;

        hqmfjs = {}
        <%= init_js_frameworks %>
        
        var patient_api = new hQuery.Patient(patient);

        // clear out logger
        if (typeof Logger != 'undefined') Logger.logger = [];
        // turn on logging if it is enabled
        if (Logger.enabled) enableLogging();
        
        #{measure_js}
        
        var population = function() {
          return hqmfjs.IPP(patient_api);
        }
        var denominator = function() {
          return hqmfjs.DENOM(patient_api);
        }
        var numerator = function() {
          return hqmfjs.NUMER(patient_api);
        }
        var exclusion = function() {
          return false;
        }
        
        if (Logger.enabled) enableMeasureLogging(hqmfjs);
        
        map(patient, population, denominator, numerator, exclusion);
      };
      "
      
      measure_def['map_fn'] = map
      
      bundle_def = JSON.parse(File.open(File.join(measures,'bundle.json')).read)
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