class Measure
  include Mongoid::Document
  
  field :nqf_id, type: String
  field :title, type: String
  field :description, type: String
  field :published, type: Boolean
  field :publish_date, type: Date
  field :version, type: Integer
  
  belongs_to :user
  embeds_many :publishings

  scope :published, -> {where({'published'=>true})}

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
  
  private 
  
  def as_publishing
    Publishing.new(self.attributes.except('_id','publishings', 'published', 'nqf_id'));
  end
  
end
