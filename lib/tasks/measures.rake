require File.expand_path('../../../config/environment',  __FILE__)
require 'pathname'
require 'fileutils'
require './lib/measures/database_access'
require './lib/measures/importer'
require './lib/measures/exporter'

namespace :measures do

  desc 'Create measure definitions'
  task :export,[:id] do |t, args|
    measure = Measure.by_measure_id(args.id)

    measure_path = File.join(".", "tmp", "measures")
    FileUtils.mkdir_p measure_path
    file = File.open(File.expand_path(File.join(measure_path, "measures.zip")), 'w')

    zip = Measures::Exporter.export(file, measure)
  end
  
  desc 'Remove the measures and bundles collection'
  task :drop_measures do
    loader = Measures::Loader.new()
    loader.drop_measures()
  end

  desc 'Load a set of measures for popHealth'
  task :import, [:measures_zip, :db_name, :db_host, :db_port] do |task, args|
    importer = Measures::Importer.new(args.db_name, args.db_host, args.db_port)
    importer.drop_measures()
    zip = File.open(args.measures_zip)
    
    importer.import(zip)
  end
  
  desc 'Convert a measure defintion to a format that can be loaded into popHealth'
  task :build, [:hqmf, :codes, :include_library, :patient] do |t, args|

    FileUtils.mkdir_p File.join(".","tmp",'measures')
    file = File.expand_path(args.hqmf)
    version = HQMF::Parser::HQMF_VERSION_1
    filename = Pathname.new(file).basename
    doc = HQMF::Parser.parse(File.open(file).read, version)

    gen = HQMF2JS::Generator::JS.new(doc)

    codes_file = File.expand_path(args.codes)
    codes = HQMF2JS::Generator::CodesToJson.from_xls(codes_file)

    if args.patient
      patient_file = File.expand_path(args.patient)
      fixture_json = File.read(patient_file)
    end

    out_file = File.join(".","tmp",'measures',"#{filename}.js")
    File.open(out_file, 'w') do |f| 

      if args.include_library
        f.write("map_reduce_utils_js = #{File.open(File.join('.','lib','assets','javascripts','libraries','map_reduce_utils.js')).read}")
        f.write("map_reduce_utils_js();")
        f.write("underscore_js = #{File.open(File.join('.','lib','assets','javascripts','libraries','underscore_min.js')).read}")
        f.write("underscore_js();")
        library_functions = HQMF2JS::Generator::JS.library_functions if args.include_library
        f.write(library_functions) 
      end

      f.write(gen.to_js(codes))

      if args.patient
        f.write("// #########################\n")
        f.write("// ######### PATIENT #######\n")
        f.write("// #########################\n\n")

        f.write("var patient_json = #{fixture_json};\n")
        initialize_patient = 'var patient = new hQuery.Patient(patient_json);'
        f.write("#{initialize_patient}\n")
      end

    end

    puts "wrote measure defintion to: #{out_file}"

    class ErbContext < OpenStruct
      def initialize(vars)
        super(vars)
      end
      def get_binding
        binding
      end
    end

    template_str = File.read(File.join('.','test','fixtures','html','test_measure.html.erb'))
    template = ERB.new(template_str, nil, '-', "_templ_html")
    params = {'measure_id' => filename}
    context = ErbContext.new(params)
    result = template.result(context.get_binding)

    out_file = File.join(".","tmp",'measures',"#{filename}.html")
    File.open(out_file, 'w') do |f| 
      f.write(result)
    end

    puts "wrote test html to: #{out_file}"

  end
  
  
end
