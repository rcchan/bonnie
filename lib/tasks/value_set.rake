namespace :import do
  desc 'import xls for value sets'
  task :value_sets, [:file] => :environment do |task, args|
    file = args.file
    if !file || file.blank?
      raise "USAGE: rake import:value_sets[file_path]"
    else
      vsp = HQMF::ValueSet::Parser.new()
      value_sets = vsp.parse(file, {format: :xls})
      
      value_sets.each do |value_set|
        ValueSet.new(value_set).save!
      end
      
      puts "Imported #{value_sets.count} value #{"set".pluralize(value_sets.count)} from #{file}."
    end
  end
  
end