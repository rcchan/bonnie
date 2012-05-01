module Measures
  
  # Utility class for loading measure definitions into the database
  class Loader
    
    def self.load(hqmf_path, value_set_path, user, value_set_format=nil)
      
      measure = Measure.new

      # Meta data
      measure.user = user

      # Value sets
      if value_set_path
        value_set_parser = HQMF::ValueSet::Parser.new()
        value_set_format ||= HQMF::ValueSet::Parser.get_format(value_set_path)
        value_sets = value_set_parser.parse(value_set_path, {format: value_set_format})
        value_sets.each do |value_set|
          set = ValueSet.new(value_set)
          set.measure = measure
          set.save!
        end
      end

      # Parsed HQMF
      if hqmf_path
        hqmf_contents = Nokogiri::XML(File.new hqmf_path).to_s
        hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1)
        json = hqmf.to_json
        
        measure.measure_id = json[:id]
        measure.title = json[:title]
        measure.description = json[:description]
        measure.measure_attributes = json[:attributes]
        
        measure.category = 'Miscellaneous'
        #measure.endorser = params[:measure][:endorser]
        #measure.steward = params[:measure][:steward]

        measure.population_criteria = json[:population_criteria]
        measure.data_criteria = json[:data_criteria]
        measure.measure_period = json[:measure_period]
      end

      measure.save!
      measure

    end
    
  end
end