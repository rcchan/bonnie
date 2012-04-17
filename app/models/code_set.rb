class CodeSet
  include Mongoid::Document
  
  field :code_set, type: String
  field :concept, type: String
  field :oid, type: String
  field :category, type: String
  field :description, type: String

end