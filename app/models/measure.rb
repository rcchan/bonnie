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

  def unique_data_criteria
    unique_criteria = []
    data_criteria.each do |key, criteria|
      identifying_fields = ["title","description","standard_category","qds_data_type","code_list_id","type","status"]
      unique = unique_criteria.select {|current| identifying_fields.reduce(true) { |all_match, field| all_match &&= current[field] == criteria[field]} }.count == 0
      unique_criteria << criteria if unique
    end if data_criteria
    unique_criteria
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
  def parameter_json(population=0, inline=false)
    parameter_json = {}
    population = population.to_i || 0
    title_mapping = {
      "IPP#{population > 0 ? '_' + population.to_s : ''}" => "population",
      "DENOM#{population > 0 ? '_' + population.to_s : ''}" => "denominator",
      "NUMER#{population > 0 ? '_' + population.to_s : ''}" => "numerator",
      "EXCL#{population > 0 ? '_' + population.to_s : ''}" => "exclusions",
      "DENEXCEP#{population > 0 ? '_' + population.to_s : ''}" => "exceptions"
    }

    self.population_criteria.each do |population, criteria|
      parameter_json[title_mapping[population]] = {
        conjunction: "and",
        items: parse_hqmf_preconditions(criteria, inline)
      }
    end

    parameter_json
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
      "measure_period" => self.measure_period,
      "attributes" => self.measure_attributes
    }

    HQMF::Document.from_json(json)
  end

  def upsert_data_criteria(criteria)
    self.data_criteria ||= {}
    self.data_criteria[criteria['id']] ||= {}
    self.data_criteria[criteria['id']].merge!(criteria)
  end

  private

  def as_publishing
    Publishing.new(self.attributes.except('_id','publishings', 'published', 'nqf_id'));
  end

  # This is a helper for parameter_json.
  # Return recursively generated JSON that can be imported into popHealth or shown as parameters in Bonnie.
  def parse_hqmf_preconditions(criteria, inline=false)
    conjunction_mapping = { "allTrue" => "and", "atLeastOneTrue" => "or" } # Used to convert to stage one, if requested in version param

    if criteria["conjunction?"] # We're at the top of the tree
      fragment = []
      criteria["preconditions"].each do |precondition|
        fragment << parse_hqmf_preconditions(precondition, inline)
      end
      return fragment
    else # We're somewhere in the middle
      element = {
        conjunction: conjunction_mapping[criteria["conjunction_code"]] || criteria["conjunction_code"],
        items: [],
        negation: criteria["negation"]
      }
      criteria["preconditions"].each do |precondition|
        if precondition["reference"] # We've hit a leaf node - This is a data criteria reference
          element[:items] << if inline
            data_criteria[precondition["reference"]].merge(
              if data_criteria[precondition["reference"]]['temporal_references']
                {
                  'temporal_references' => data_criteria[precondition["reference"]]['temporal_references'].map {|r|
                    r.merge(
                      if r['reference'] != 'MeasurePeriod'
                        {'reference' => data_criteria[r['reference']]}
                      else {title: 'MeasurePeriod'}
                      end
                    )
                  }
                }
              else {}
              end
            ) else {id: precondition["reference"]}
          end
        end
        if precondition['preconditions']
          precondition['conjunction_code'] = 'and' if precondition["reference"]
          element[:items] << parse_hqmf_preconditions(precondition, inline)
        end

      end if criteria["preconditions"]
      return element
    end

  end
end
