class ValueSet
  include Mongoid::Document
  
  field :concept, type: String
  field :oid, type: String
  field :code_set, type: String
  field :category, type: String
  field :description, type: String
  embeds_many :codes, class_name: "ValueSet"
  
  Categories = %w(
    encounter
    procedure
    risk_category_assessment
    communication
    laboratory_test
    physical_exam
    medication
    diagnosis_condition_problem
    symptom
    individual_characteristic
    device
    care_goal
    diagnostic_study
    substance
  )
  
  set_callback(:save, :before) do |document|
    document.codes.reject! { |code| code.blank? }
  end
  
  validates_inclusion_of :category, in: Categories
  validates_format_of :oid, with: /^[\d*\.\d]+$/
end
