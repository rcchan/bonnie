module Measures
  
  # Exports measure defintions in a pophealth compatible format
  class Exporter
    def self.export(file, measures)
      
      Zip::ZipOutputStream.open(file.path) do |zip|      
        measure_path = "measures"
        json_path = File.join(measure_path, "json")
        library_path = File.join(measure_path, "libraries")

        library_functions = Measures::Exporter.library_functions

        library_functions.each do |name, contents|
          zip.put_next_entry(File.join(library_path, "#{name}.js"))
          zip << contents
        end

        bundle_json = Measures::Exporter.bundle_json(library_functions.keys).to_json
        zip.put_next_entry(File.join(measure_path, "bundle.json"))
        zip << bundle_json

        measures.each do |measure|
          measure_json = Measures::Exporter.measure_json(measure.measure_id).to_json
          zip.put_next_entry(File.join(json_path, "#{measure.measure_id}.json"))
          zip << measure_json
        end
      end
    end
    
    def self.library_functions
      library_functions = {}
      library_functions['map_reduce_utils'] = File.read(File.join('.','lib','assets','javascripts','libraries','map_reduce_utils.js'))
      library_functions['underscore_min'] = File.read(File.join('.','lib','assets','javascripts','libraries','underscore_min.js'))
      library_functions['hqmf_utils'] = HQMF2JS::Generator::JS.library_functions
      library_functions
    end
    
    def self.measure_json(measure_id)
      measure = Measure.by_measure_id(measure_id).first
      buckets = measure.parameter_json
      
      {
        id: measure.measure_id,
        endorser: measure.endorser,
        name: measure.title,
        description: measure.description,
        category: measure.category,
        steward: measure.steward,
        population: buckets["population"],
        denominator: buckets["denominator"],
        numerator: buckets["numerator"],
        exclusions: buckets["exclusions"],
        map_fn: measure_js(measure),
        measure: {}
      }
    end
    
    def self.bundle_json(library_names)
      {
        name: "Meaningful Use Stage 2 Clinical Quality Measures",
        license: "<p>Performance measures and related data specifications (the \"Measures\") are copyrighted by\nthe noted quality measure providers as indicated in the applicable Measure.  Coding\nvocabularies are owned by their copyright owners.  By using the Measures, a user\n(\"User\") agrees to these Terms of Use.  Measures are not clinical guidelines and do not\nestablish a standard of medical care and quality measure providers are not responsible\nfor any use of or reliance on the Measures.</p>\n\n<p><strong>THE MEASURES AND SPECIFICATIONS ARE PROVIDED \"AS IS\" WITHOUT ANY WARRANTY OF\nANY KIND, AND ANY AND ALL IMPLIED WARRANTIES ARE HEREBY DISCLAIMED, INCLUDING ANY\nWARRANTY OF NON-INFRINGEMENT, ACCURACY, MERCHANTABILITY AND FITNESS FOR A PARTICULAR\nPURPOSE.  NO QUALITY MEASURE PROVIDER, NOR ANY OF THEIR TRUSTEES, DIRECTORS, MEMBERS,\nAFFILIATES, OFFICERS, EMPLOYEES, SUCCESSORS AND/OR ASSIGNS WILL BE LIABLE TO YOU FOR\nANY DIRECT, INDIRECT, SPECIAL, EXEMPLARY, INCIDENTAL, PUNITIVE, AND/OR CONSEQUENTIAL\nDAMAGE OF ANY KIND, IN CONTRACT, TORT OR OTHERWISE, IN CONNECTION WITH THE USE OF THE\nPOPHEALTH TOOL OR THE MEASURES, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH LOSS OR DAMAGE.\n</strong></p>\n\n<p>The Measures are licensed to a User for the limited purpose of using, reproducing and\ndistributing the Measures with the popHealth Tool as delivered to User, without any\nmodification, for commercial and noncommercial uses, but such uses are only permitted\nif the copies of the Measures contain this complete Copyright, Disclaimer and Terms\nof Use.  Users of the Measures may not alter, enhance, or otherwise modify the Measures.</p>\n\n<p><strong>NOT A CONTRIBUTION</strong> - The Measures, including specifications and coding,\nas used in the popHealth Tool, are not a contribution under the Apache license. Coding\nin the Measures is provided for convenience only and necessary licenses for use should\nbe obtained from the copyright owners. Current Procedural Terminology \n(CPT<span class=\"reg\">&reg;</span>) &copy; 2004-2010 American Medical Association. \nLOINC<span class=\"reg\">&reg;</span> &copy; 2004 Regenstrief Institute,\nInc. SNOMED Clinical Terms<span class=\"reg\">&reg;</span> \n(SNOMED CT<span class=\"reg\">&reg;</span>) &copy; 2004-2010 International Health\nTerminology Standards Development Organization.</p>",
        extensions: library_names,
        measures: []
      }
    end

    def self.measure_codes(measure)
      HQMF2JS::Generator::CodesToJson.from_value_sets(measure.value_sets)
    end

    private
    
    def self.measure_js(measure)
      "function() {
        var patient = this;
        var effective_date = <%= effective_date %>;

        hqmfjs = {}
        <%= init_js_frameworks %>
        
        #{execution_logic(measure)}
      };
      "
    end
    
    def self.execution_logic(measure)
      gen = HQMF2JS::Generator::JS.new(measure.as_hqmf_model)
      codes = measure_codes(measure)
      "
      var patient_api = new hQuery.Patient(patient);

      // clear out logger
      if (typeof Logger != 'undefined') Logger.logger = [];
      // turn on logging if it is enabled
      if (Logger.enabled) enableLogging();
      
      #{gen.to_js(codes)}
      
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
      "
    end
  end
end