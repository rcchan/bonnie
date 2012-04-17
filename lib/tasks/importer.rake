require 'value_set_importer'

namespace :import do
  desc 'import xls'
  task :xls, [:file] => :environment do |task, args|
    file = args.file
    if !file || file.blank?
      raise "USAGE: rake import:xls[file_path]"
    else
      vsi = ValueSetImporter.new()
      rows_imported = vsi.import(file, {:sheet => 1, :columns => 2})
      puts "Imported #{rows_imported} value #{"set".pluralize(rows_imported)} from #{file}."
    end
  end
end