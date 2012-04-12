require 'measure_importer'

namespace :import do
  desc 'import xls'
  task :xls, :file do |file|
    if !args.file
      raise "please specify an excel file."
    end
    measure_importer = MeasureImporter.new(args.file)
    measure_importer.run
  end
end