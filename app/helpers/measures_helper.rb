module MeasuresHelper
  
  # create a javascript object for the debug view
  def include_js_debug(measure_id)
    hqmf_path = File.expand_path(File.join('.','test','fixtures','measure-defs',measure_id,"#{measure_id}.xml"))
    codes_path = File.expand_path(File.join('.','test','fixtures','measure-defs',measure_id,"#{measure_id}.xls"))
    filename = Pathname.new(hqmf_path).basename
    
    measure = Measures::Loader.load(hqmf_path, codes_path, nil, nil, false)
    measure_js = Measures::Exporter.execution_logic(measure)
    
    patient_file = File.expand_path('./test/fixtures/patients/francis_drake.json')
    patient_json = File.read(patient_file)
    
    @js = ""
    library_functions = Measures::Exporter.library_functions
    ['map_reduce_utils'].each do |function|
      @js << "#{function}_js = function () { #{library_functions[function]} }\n"
      @js << "#{function}_js();\n"
    end
    
    @js << library_functions['hqmf_utils'] + "\n"
    
    @js << "execute_measure = function(patient) {\n #{measure_js} \n}\n"
    @js << "emitted = []; emit = function(id, value) { emitted.push(value); } \n"
    @js << "ObjectId = function(id, value) { return 1; } \n"
    
    @js << "// #########################\n"
    @js << "// ######### PATIENT #######\n"
    @js << "// #########################\n\n"
    
    @js << "var patient = #{patient_json};\n"

    return @js
  end

  def dc_category_style(category)
    case category
    when 'diagnosis_condition_problem'
      'diagnosis'
    when 'laboratory_test'
      'laboratory'
    when 'individual_characteristic'
      'patient'
    else
      category
    end
  end
  
  def dc_title(title)
    result = title
    
    sections = title.split(':')
    if (sections.size > 1)
      category = sections[0]
      category_sections = category.split(",")
      if (category_sections.size > 1)
        category = category_sections[0]
      end
      title = title[(category.length+1)..title.length].strip
    end
    
  end
  
end
