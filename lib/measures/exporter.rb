module Measures
  
  # Exports measure defintions in a pophealth compatible format
  class Exporter
    
    def libraryFunctions
      
      library_functions = {}
      library_functions['map_reduce_utils'] = File.read(File.join('.','lib','assets','javascripts','libraries','map_reduce_utils.js'))
      library_functions['underscore_min'] = File.read(File.join('.','lib','assets','javascripts','libraries','underscore_min.js'))
      library_functions['hqmf_utils'] = HQMF2JS::Generator::JS.library_functions
      library_functions
    end
    
    def measure_json
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
      
      measure_def
    end
    
    def bundle_json
      bundle_def = JSON.parse(File.open(File.join(measures,'bundle.json')).read)
    end

  end
  
end