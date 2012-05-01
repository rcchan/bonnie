class Measure
  include Mongoid::Document
  
  field :endorser, type: String
  field :measure_id, type: String
  field :title, type: String
  field :description, type: String
  field :category, type: String
  field :steward, type: String    # organization who's writing the measure
  
  field :published, type: Boolean
  field :publish_date, type: Date
  field :version, type: Integer

  field :population_criteria, type: Hash
  field :data_criteria, type: Hash
  field :measure_period, type: Hash
  field :measure_attributes, type: Hash

  belongs_to :user
  embeds_many :publishings
  has_many :value_sets

  scope :published, -> { where({'published'=>true}) }
  scope :by_measure_id, ->(id) { where({'measure_id'=>id }) }
  scope :by_user, ->(user) { where({'user_id'=>user.id}) }

  # Create or increment all of the versioning information for this measure
  def publish
    self.publish_date = Time.now
    self.version ||= 0
    self.version += 1
    self.published=true
    self.publishings << as_publishing
    self.save!
  end
  
  def latest_version
    publishings.by_version(self.version).first
  end
  
  # Reshapes the measure into the JSON necessary to build the popHealth parameter view for stage one measures.
  # Returns a hash with population, numerator, denominator, and exclusions
  def parameter_json version = HQMF::Parser::HQMF_VERSION_1
    parameter_json = {}
    
    title_mapping = { "IPP" => "population", "DENOM" => "denominator", "NUMER" => "numerator", "EXCL" => "exclusions"}
    self.population_criteria.each do |population, criteria|
      title = title_mapping[population]
      logic_json = parse_hqmf_preconditions(criteria, version)
      
      # Parameters don't begin with conjunctions in stage 1 JSON
      if version == HQMF::Parser::HQMF_VERSION_1
        top_conjunction = logic_json.keys.first
        if logic_json[top_conjunction].size == 1 && logic_json.keys.size == 1
          logic_json = logic_json[top_conjunction].first
        end
      end
      
      parameter_json[title] = logic_json
    end
    
    parameter_json
  end
  
  # Returns the hqmf-parser's ruby implementation of an HQMF document.
  # Rebuild from population_criteria, data_criteria, and measure_period JSON
  def as_hqmf_model
    json = {
      id: self.measure_id,
      title: self.title,
      description: self.description,
      population_criteria: self.population_criteria,
      data_criteria: self.data_criteria,
      measure_period: self.measure_period,
      attributes: self.measure_attributes
    }
    
    HQMF::Document.from_json(json)
  end
  
  private 
  
  def as_publishing
    Publishing.new(self.attributes.except('_id','publishings', 'published', 'nqf_id'));
  end
  
  # This is a helper for parameter_json.
  # Return recursively generated JSON that can be imported into popHealth or shown as parameters in Bonnie.
  def parse_hqmf_preconditions(criteria, version)
    fragment = {}
    conjunction_mapping = { "allTrue" => "and", "atLeastOneTrue" => "or" } # Used to convert to stage one, if requested in version param
    
    if criteria["conjunction?"] # We're at the top of the tree
      criteria["preconditions"].each do |precondition|
        fragment.merge! parse_hqmf_preconditions(precondition, version)
      end
    else # We're somewhere in the middle
      conjunction = criteria["conjunction_code"]
      conjunction = conjunction_mapping[conjunction] if conjunction_mapping[conjunction] && version == HQMF::Parser::HQMF_VERSION_1
      fragment[conjunction] = []
      criteria["preconditions"].each do |precondition|
        if precondition["reference"] # We've hit a leaf node - This is a data criteria reference
          fragment[conjunction] << parse_hqmf_data_criteria(data_criteria[precondition["reference"]])
        else # There are additional layers below
          fragment[conjunction] << parse_hqmf_preconditions(precondition, version)
        end
      end
    end
    
    fragment
  end
  
  # This is a helper for parse_hqmf_preconditions.
  # Return a human readable title and category for a given data criteria
  def parse_hqmf_data_criteria(criteria)
    fragment = {}
    name = criteria["property"].to_s
    category = criteria["standard_category"]
    
    # QDS data type is most specific, so use it if available. Otherwise use the standard category.
    category_mapping = { "individual_characteristic" => "patient characteristic" }
    if criteria["qds_data_type"]
      category = criteria["qds_data_type"].gsub(/_/, " ") # "medication_administered" = "medication administered"
    elsif category_mapping[category]
      category = category_mapping[category]
    end
    
    if criteria["value"] # Some exceptions have the value key. Bump it forward so criteria is idenical to the format of usual coded entries
      criteria = criteria["value"]
    else # Find the display name as per usual for the coded entry
      last_word_of_category = category.split.last
      criteria["title"] =~ /#{last_word_of_category}. (.*)/i # The portion after autoformatted text, i.e. actual name (e.g. pneumococcal vaccine)
      name = $1
      criteria = criteria["effective_time"]
    end
    
    measure_period["name"] = "the measure period"
    temporal_text = parse_hqmf_time(criteria, measure_period)
    title = "#{name} #{temporal_text}"
    
    fragment["title"] = title
    fragment["category"] = category
    fragment
  end

  # This is a helper for parse_hqmf_data_criteria.
  # Return recursively generated human readable text about time ranges and periods
  def parse_hqmf_time(criteria, relative_time)
    temporal_text = ""
    
    type = criteria["type"]
    case type
    when "IVL_TS"
      temporal_text = "#{parse_hqmf_time(criteria["width"], relative_time)} " if criteria["width"]
      
      temporal_text += ">#{parse_hqmf_time_stamp("low", criteria, relative_time)} start" if criteria["low"]
      temporal_text += " and " if criteria["low"] && criteria["high"]
      temporal_text += "<#{parse_hqmf_time_stamp("high", criteria, relative_time)} end" if criteria["high"]
    when "IVL_PQ"
      temporal_text = parse_hqmf_time_vector(criteria["low"], ">") if criteria["low"]
      temporal_text += " and " if criteria["low"] && criteria["high"]
      temporal_text += parse_hqmf_time_vector(criteria["high"], "<") if criteria["high"]
    end
    
    temporal_text
  end
  
  def parse_hqmf_time_stamp(point, timestamp, relative_timestamp)
    if timestamp[point]["value"] == relative_timestamp[point]["value"]
      "= #{relative_timestamp["name"]}"
    else
      year = timestamp[point]["value"][0..3]
      month = timestamp[point]["value"][4..5]
      day = timestamp[point]["value"][6..7]
      
      " #{Time.new(year, month, day).strftime("%m/%d/%Y")}"
    end
  end
  
  def parse_hqmf_time_vector(vector, symbol)
    temporal_text = symbol
    
    temporal_text += "=" if vector["inclusive?"]
    temporal_text += " #{vector["value"]} "
    
    case vector["unit"]
    when "a"
      temporal_text += "year"
    when "mo"
      temporal_text += "month"
    when "d"
      temporal_text += "day"
    when "h"
      temporal_text += "hour"
    when "min"
      temporal_text += "minute"
    end
    temporal_text += "s" if vector["value"] != 1
    
    temporal_text
  end
end
