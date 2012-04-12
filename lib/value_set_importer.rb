require 'zip/zipfilesystem'
require 'spreadsheet'
require 'google_spreadsheet'
require 'roo'
require 'iconv'

class ValueSetImporter
  
  def initialize()
  end
  
  def file_to_array(file_path, options)
    defaults = {
      :columns => 2,  # range of import
      :sheet => 0     # only one sheet at a time can be worked on
    }
    options = defaults.merge(options)
    
    book = Excelx.new(file_path)
    book.default_sheet=book.sheets[options[:sheet]]

    book.to_matrix.to_a
  end
  
  # import an excel matrix array into mongo
  def import(sheet_array)
    headers = sheet_array.pop
    
    # map columns from the spreadsheet to rails model
    sheet_array.each do |row|
      vs = ValueSet.new(
        :organization => row[0],
        :oid => row[1],
        :concept => row[2],
        :category => row[3],
        :code_set => row[4],
        :codes => [],
        :version => row[5],
        :description => row[6]
      )
    end
  end
  
  # take an excel matrix array and turn it into an array of db models
  def cells_to_docs(array)
    a = Array.new(array)                  # new variable for reentrant
    headers = a.shift.map {|i| i.to_s }   # because of this shift
    string_data = a.map {|row| row.map {|cell| cell.to_s } }
    array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }

    value_sets = []   # for manipulation before saving to mongodb
    array_of_hashes.each do |row|
      vs = ValueSet.new(
        :organization => row["measure developer and/or codelist developer"],
        :oid => row["standard OID"],
        :concept => row["standard concept"],
        :category => row["standard category"].parameterize.gsub('-','_'),
        :code_set => row["standard taxonomy"],
        :version => row["standard taxonomy version"],
        :code => row["code"],
        :description => row["descriptor"]
      )
      
      value_sets << vs
    end
    
    value_sets
  end
  
  def group_tree(array)
    mongo_objects = cells_to_docs(array)
    
    # find all parents with GROUPING attribute
    parent_groups = mongo_objects.select {|o| o[:code_set] == "GROUPING" }
    parent_groups.each do |parent|
      children = mongo_objects.select {|o| o[:oid] == parent[:code]}
      first_child = children.first
      code_sets = []
      tmp_hash = {}
      tmp_hash[:set] = first_child[:code_set]
      tmp_hash[:version] = first_child[:version]
      tmp_hash[:codes] = children.collect {|c| c[:code] }
      code_sets << tmp_hash
      parent[:code_sets] = code_sets
    end
    
    # Pull up all the unmarked groupings.  The algorithm for this is:
    # Find all the unique OIDs in OID column from spreadsheet.  But keep the object ref.
    # Search all codes column for each OID.
    # All that do not have a match, pull up as groupings.
    # Pull up means create a grouping parent like parent_groups above with similar attributes.
    unique_oids = mongo_objects.uniq(&:oid)
    pull_ups = unique_oids.select {|o| !o[:code].in?(unique_oids.collect(&:oid)) }
    pull_ups.reject! {|pu| pu[:oid].in?(parent_groups.collect(&:code)) }
    pull_ups.each do |pu|      # pull up attributes
      pu[:code_sets] = [
        {:set => pu[:code_set], :version => pu[:version], :codes => [ pu[:code] ] }
      ]
      pu.remove_attribute :version
      pu.remove_attribute :code_set
      pu.remove_attribute :code
    end
    
    tree = pull_ups + parent_groups
  end
  
end
