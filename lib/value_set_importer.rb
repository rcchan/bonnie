require 'zip/zipfilesystem'
require 'spreadsheet'
require 'google_spreadsheet'
require 'roo'
require 'iconv'

class ValueSetImporter
  
  GROUP_CODE_SET = "GROUPING"
  
  def initialize()
  end
  
  # import an excel matrix array into mongo
  def import(file, options)
    sheet_array = file_to_array(file, options)
    by_oid_ungrouped = cells_to_hashs_by_oid(sheet_array)
    final = collapse_groups(by_oid_ungrouped)
    
  end
  
  def collapse_groups(by_oid_ungrouped)
    
    final = []
    
    # select the grouped code sets and fill in the children... also remove the children that are a
    # member of a group.  We remove the children so that we can create parent groups for the orphans
    (by_oid_ungrouped.select {|key,value| value[:code_set] == GROUP_CODE_SET}).each do |key, value|
      # remove the group so that it is not in the orphan list
      by_oid_ungrouped.delete(value[:oid])
      codes = []
      value[:codes].each do |child_oid|
        codes << by_oid_ungrouped.delete(child_oid)
        # for hierarchies we need to probably have codes be a hash that we select from if we don't find the
        # element in by_oid_ungrouped we may need to look for it in final
      end
      value[:codes] = codes
      final << value
    end
    
    # fill out the orphans
    by_oid_ungrouped.each do |key, orphan|
      final << adopt_orphan(orphan)
    end
    
  end
  
  def adopt_orphan(orphan)
    parent = orphan.dup
    parent[:codes] = [orphan]
    parent
  end
  
  # take an excel matrix array and turn it into an array of db models
  def cells_to_hashs_by_oid(array)
    a = Array.new(array)                  # new variable for reentrant
    headers = a.shift.map {|i| i.to_s }   # because of this shift
    string_data = a.map {|row| row.map {|cell| cell.to_s } }
    array_of_hashes = string_data.map {|row| Hash[*headers.zip(row).flatten] }

    by_oid = {}
    array_of_hashes.each do |row|
      entry = convert_row(row)
      
      existing = by_oid[entry[:oid]]
      if (existing)
        existing[:codes].concat(entry[:codes])
      else
        by_oid[entry[:oid]] = entry
      end
    end
    
    by_oid
  end
  
  private
  
  def convert_row(row)
    # Value Set Developer
    # Value Set OID
    # Value Set Name
    # QDM Category
    # Code System
    # Code System Version
    # Code
    # Descriptor
    {
      :organization => row["Value Set Developer"],
      :oid => row["Value Set OID"].strip,
      :concept => row["Value Set Name"],
      :category => row["QDM Category"].parameterize.gsub('-','_'),
      :code_set => row["Code System"],
      :version => row["Code System Versionn"],
      :codes => extract_code(row["Code"], row["Code System"]),
      :description => row["Descriptor"]
    }
  end
  
  def extract_code(code, set)
    
    code.strip!
    if set=='CPT' && code.include?('-')
      eval(code.strip.gsub('-','..')).to_a.collect { |i| i.to_s }
    else
      [code]
    end
    
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
  
  
end
