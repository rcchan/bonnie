class Measure
  include Mongoid::Document
  
  field :nqf_id, :type => String
  field :title, :type => String
  field :description,    :type => String
  
  belongs_to :user
  
end
