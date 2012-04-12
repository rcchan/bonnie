require 'test_helper'
require 'value_set_importer'
require 'pp'

class ValueSetImporterTest < ActiveSupport::TestCase
  
  setup do
    dump_database
  end
  
  test 'it reads an excel file' do
    file = "test/fixtures/value_set_import_test.xlsx"
    vsi = ValueSetImporter.new()
    # change to second sheet in workbook
    sheet = vsi.file_to_array(file, {:sheet => 1, :columns => 2})
    sheet.must_respond_to(:each)
  end
  
  test 'it imports a single excel file' do
    file = "test/fixtures/value_set_import_test.xlsx"
  
    old_measures = ValueSet.all    
    vsi = ValueSetImporter.new()
    options = {:sheet => 1, :columns => 2}
    sheet = vsi.file_to_array(file, options)  # change to second sheet in workbook
    sheet.must_respond_to(:each)
    vsi.import(sheet)
    
    new_measures = ValueSet.all
    
    # assert_equal(false, old_measures == new_measures)
  end
  
  test 'it creates a valueset hierarchy' do
    vsi = ValueSetImporter.new()
    
    sample = [
      ["measure developer and/or codelist developer", "standard OID", "standard concept",
        "standard category", "standard taxonomy", "standard taxonomy version", "code",
        "descriptor"],
      ["National Committee for Quality Assurance", "2.16.840.1.113883.3.464.0001.14", "birth
        date", "Individual characteristic", "HL7", "3.0", "00110", "Date/Time of birth (TS)"],
      ["National Committee for Quality Assurance", "2.16.840.1.113883.3.464.0001.48", "encounter
        outpatient", "Encounter", "CPT", "06/2009", "99201", nil], ["National Committee for
        Quality Assurance", "2.16.840.1.113883.3.464.0001.48", "encounter outpatient",
      "Encounter", "CPT", "06/2009", "99202", nil], 
      ["National Committee for Quality Assurance",
        "2.16.840.1.113883.3.464.0001.49", "encounter outpatient", "Encounter", "GROUPING", "n/a",
        "2.16.840.1.113883.3.464.0001.48", '"encounter outpatient" CPT code list']
    ]
        
    structure = vsi.group_tree(sample)
    group_parent = structure.select {|vs| vs[:oid] == "2.16.840.1.113883.3.464.0001.49"}
    group_parent.first[:code_sets].first[:codes].length.must_equal 2
    
    pulled_up_parent = structure.select {|vs| vs[:oid] == "2.16.840.1.113883.3.464.0001.14"}
    pulled_up_parent.first[:code_sets].first[:codes].length.must_equal 1
  end
  
end
