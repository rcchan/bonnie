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
    
    if !(file_path =~ /xls$/).nil?
      book = Excel.new(file_path)
    elsif !(file_path =~ /xlsx$/).nil?
      book = Excelx.new(file_path)
    else
      raise "File does not end in .xls or .xlsx"
    end
    book.default_sheet=book.sheets[options[:sheet]]
    
    # catch double byte encoding problems in spreadsheet files
    # Encoding::InvalidByteSequenceError: "\x9E\xDE" on UTF-16LE
    begin
      book.to_matrix.to_a
    rescue Encoding::InvalidByteSequenceError => e
      raise "Spreadsheet encoding problem: #{e}"
    end
  end
  
  # import an excel matrix array into mongo
  def import(file, options)
    sheet_array = file_to_array(file, options)
    tree = group_tree(sheet_array)

    count = 0
    tree.each do |doc|
      count += 1
      begin
        doc.save!
      rescue
        binding.pry
      end
    end
    count
  end
  
  # take an excel matrix array and turn it into an array of db models
  def cells_to_docs(array)
    a = Array.new(array)                  # new variable for reentrant
    headers = a.shift.map {|i| i.to_s }   # because of this shift
    string_data = a.map {|row| row.map {|cell| cell.to_s } }
    array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }

    value_sets = []   # for manipulation before saving to mongodb
    array_of_hashes.each do |row|
      # Value Set Developer
      # Value Set OID
      # Value Set Name
      # QDM Category
      # Code System
      # Code System Version
      # Code
      # Descriptor
      vs = ::ValueSet.new(
        :organization => row["Value Set Developer"],
        :oid => row["Value Set OID"].strip,
        :concept => row["Value Set Name"],
        :category => row["QDM Category"].parameterize.gsub('-','_'),
        :code_set => row["Code System"],
        :version => row["Code System Versionn"],
        :code => row["Code"],
        :description => row["Descriptor"]
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
      if children.count == 0
        # parents markeded as GROUPING with no children in spreadsheet
        break
      end
      first_child = children.first
      code_sets = []
      tmp_hash = {}
      tmp_hash[:set] = first_child[:code_set]
      tmp_hash[:version] = first_child[:version] unless first_child[:version].nil?
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
