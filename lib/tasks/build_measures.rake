require 'pathname'
require 'fileutils'

namespace :build do
  desc 'Convert a measure defintion to a format that can be loaded into popHealth'
  task :measure, [:hqmf, :codes, :patient] do |t, args|
    
    FileUtils.mkdir_p File.join(".","tmp",'measures')
    file = File.expand_path(args.hqmf)
    version = HQMF::Parser::HQMF_VERSION_1
    filename = Pathname.new(file).basename
    doc = HQMF::Parser.parse(File.open(file).read, version)
    
    gen = HQMF2JS::Generator::JS.new(doc)

    codes_file = File.expand_path(args.codes)
    codes = HQMF2JS::Generator::CodesToJson.from_xls(codes_file)
    
    library_functions = HQMF2JS::Generator::JS.library_functions
    
    patient_file = File.expand_path(args.patient)
    fixture_json = File.read(patient_file)
    
    out_file = File.join(".","tmp",'measures',"#{filename}.js")
    File.open(out_file, 'w') do |f| 

#      f.write(library_functions)
      
      f.write("// #########################\n")
      f.write("// ##### DATA ELEMENTS #####\n")
      f.write("// #########################\n\n")
      
      f.write("var OidDictionary = #{HQMF2JS::Generator::CodesToJson.hash_to_js(codes)};\n\n")
      f.write(gen.js_for_data_criteria())
  
      f.write("// #########################\n")
      f.write("// ##### MEASURE LOGIC #####\n")
      f.write("// #########################\n\n")
           
      f.write("// INITIAL PATIENT POPULATION\n")
      f.write(gen.js_for('IPP'))
      f.write("// DENOMINATOR\n")
      f.write(gen.js_for('DENOM'))
      f.write("// NUMERATOR\n")
      f.write(gen.js_for('NUMER'))
      f.write(gen.js_for('DENEXCEP'))
  
      
#      f.write("// #########################\n")
#      f.write("// ######### PATIENT #######\n")
#      f.write("// #########################\n\n")
#
#      f.write("var patient_json = #{fixture_json};\n")
#      initialize_patient = 'var patient = new hQuery.Patient(patient_json);'
#      f.write("#{initialize_patient}\n")
      
    end
    
    puts "wrote measure defintion to: #{out_file}"
    
    
  end
end
