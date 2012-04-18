class CodeSet
  include Mongoid::Document
  
  field :key, type: String
  field :concept, type: String
  field :oid, type: String
  field :category, type: String
  field :description, type: String
  field :organization, type: String
  field :version, type: String
  field :codes, type: Array

end