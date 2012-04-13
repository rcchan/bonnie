require 'value_set_importer'

namespace :import do
  desc 'import xls'
  task :xls, [:file] => :environment do |task, args|
    file = ENV['file']
    if !file || file.blank?
      raise "USAGE: rake import:xls file=foo"
    else
      vsi = ValueSetImporter.new()
      vsi.import(file, {:sheet => 1, :columns => 2})
    end
  end
end