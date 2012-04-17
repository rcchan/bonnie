class Measure
  include Mongoid::Document
  
  field :endorser, type: String
  field :measure_id, type: String
  field :title, type: String
  field :description, type: String
  field :category, type: String
  field :steward, type: String
  
  field :published, type: Boolean
  field :publish_date, type: Date
  field :version, type: Integer

  field :population_criteria, type: Hash
  field :data_criteria, type: Hash
  field :measure_period, type: Hash

  belongs_to :user
  embeds_many :publishings

  scope :published, -> {where({'published'=>true})}

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
  #
  # Returns a hash with population, numerator, denominator, and exclusions symbols
  # Using these conjunctions:
  #   and, or
  def stage_one_parameter_json
    binding.pry
  end
  
  # Reshapes the measure into the JSON necessary to build a stage two parameter view.
  #
  # Returns a hash with population, numerator, denominator, and exclusions symbols
  # Using these conjunctions:
  #   allTrue, atLeastOneTruie
  def stage_two_parameter_json
    
  end
  
  # Returns the javascript for this measure's map function
  def map_fn
    
  end
  
  # Returns a hash of all the concepts used in this measure, mapped to their respective category information and code sets
  def code_list
    
  end
  
  private 
  
  def as_publishing
    Publishing.new(self.attributes.except('_id','publishings', 'published', 'nqf_id'));
  end
end
