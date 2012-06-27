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
  field :data_criteria, type: Hash, default: {}
  field :source_data_criteria, type: Hash, default: {}
  field :measure_period, type: Hash
  field :measure_attributes, type: Hash
  field :populations, type: Array

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

  def data_criteria_by_oid
    by_oid = {}
    data_criteria.each do |key, criteria|
      by_oid[criteria["code_list_id"]] = criteria
    end
    by_oid
  end

  # Reshapes the measure into the JSON necessary to build the popHealth parameter view for stage one measures.
  # Returns a hash with population, numerator, denominator, and exclusions
  def parameter_json(population_index=0)
    parameter_json = {}
    population_index ||= 0
    
    population = populations[population_index]
    
    title_mapping = {
      population["IPP"] => "population",
      population["DENOM"] => "denominator",
      population["NUMER"] => "numerator",
      population["EXCL"] => "exclusions",
      population["DENEXCEP"] => "exceptions"
    }
    self.population_criteria.each do |key, criteria|
      parameter_json[title_mapping[key]] = population_criteria_json(criteria) if title_mapping[key]
    end

    parameter_json
  end
  
  def population_criteria_json(criteria)
    {
        conjunction: "and",
        items: parse_hqmf_preconditions(criteria)
    }
  end

  def self.pophealth_parameter_json(parameter_json, data_criteria)
    json = {}
    parameter_json.keys.each do |key|
      json[key] = pophealth_element_json(parameter_json[key], data_criteria)
    end
    json
  end

  def self.pophealth_element_json(json, data_criteria)
    if (json[:items])
      section = {}
      items = []
      json[:items].each do |item|
        items << pophealth_element_json(item, data_criteria)
      end
      section[json[:conjunction]] = items
      section
    else
      pophealth_criteria_json(json[:id], data_criteria)
    end
  end
  def self.pophealth_criteria_json(id, data_criteria)
    criteria = data_criteria[id]
    if criteria["children_criteria"].nil? or criteria["children_criteria"].empty?
      {"category" => criteria['standard_category'].titleize + (criteria['status'] ? ": #{criteria['status']}" : ''), "title" => criteria['title']}
    else
      pophealth_parent_criteria_json(criteria, data_criteria)
    end
  end
  def self.pophealth_parent_criteria_json(criteria, data_criteria)
    section = {}
    items = []
    criteria["children_criteria"].each do |id|
      items << pophealth_criteria_json(id, data_criteria)
    end
    section['OR'] = items
    section
  end

  # Returns the hqmf-parser's ruby implementation of an HQMF document.
  # Rebuild from population_criteria, data_criteria, and measure_period JSON
  def as_hqmf_model
    json = {
      "id" => self.measure_id,
      "title" => self.title,
      "description" => self.description,
      "population_criteria" => self.population_criteria,
      "data_criteria" => self.data_criteria,
      "source_data_criteria" => self.source_data_criteria,
      "measure_period" => self.measure_period,
      "attributes" => self.measure_attributes,
      "populations" => self.populations
    }

    HQMF::Document.from_json(json)
  end

  def upsert_data_criteria(criteria)
    self.data_criteria ||= {}
    self.data_criteria[criteria['id']] ||= {}
    self.data_criteria[criteria['id']].merge!(criteria)
  end
  
  def all_data_criteria
    data_criteria.merge(source_data_criteria)
  end

  private

  def as_publishing
    Publishing.new(self.attributes.except('_id','publishings', 'published', 'nqf_id'));
  end

  # This is a helper for parameter_json.
  # Return recursively generated JSON that can be imported into popHealth or shown as parameters in Bonnie.
  def parse_hqmf_preconditions(criteria)
    conjunction_mapping = { "allTrue" => "and", "atLeastOneTrue" => "or" } # Used to convert to stage one, if requested in version param

    if criteria["conjunction?"] # We're at the top of the tree
      fragment = []
      criteria["preconditions"].each do |precondition|
        fragment << parse_hqmf_preconditions(precondition)
      end if criteria['preconditions']
      return fragment
    else # We're somewhere in the middle
      element = {
        conjunction: conjunction_mapping[criteria["conjunction_code"]] || criteria["conjunction_code"],
        items: [],
        negation: criteria["negation"]
      }
      criteria["preconditions"].each do |precondition|
        if precondition["reference"] # We've hit a leaf node - This is a data criteria reference
          element[:items] << {id: precondition["reference"]}
        end
        if precondition['preconditions']
          precondition['conjunction_code'] = 'and' if precondition["reference"]
          element[:items] << parse_hqmf_preconditions(precondition)
        end

      end if criteria["preconditions"]
      return element
    end

  end
  
end
