class ErbContext < OpenStruct
  def initialize(vars)
    super(vars)
  end
  def get_binding
    binding
  end
end


class MeasuresController < ApplicationController
  
  layout :select_layout
  before_filter :authenticate_user!
  before_filter :validate_authorization!

  add_breadcrumb 'measures', ""
  
  rescue_from Mongoid::Errors::Validations do
    render :template => "measures/edit"
  end
  
  def index
    @measure = Measure.new
    @measures = current_user.measures
  end

  def show
    @measure = Measure.find(params[:id])
  end

  def show_nqf
    @measure = Measure.find(params[:id])
    @contents = File.read(File.expand_path(File.join('.','test','fixtures','measure-defs',@measure.measure_id,"#{@measure.measure_id}.html")))
  end
  
  def publish
    @measure = Measure.find(params[:id])
    @measure.publish
    
    render :show
  end

  def published
    @measures = Measure.published.map(&:latest_version)
  end

  def new
    @measure = Measure.new
  end
  
  def edit
    @editing=true
    @measure = Measure.find(params[:id])
  end

  def create
    
    # Value sets
    value_set_file = params[:measure][:value_sets]
    value_set_path = value_set_file.tempfile.path
    value_set_format = HQMF::ValueSet::Parser.get_format(value_set_file.original_filename)
    
    hqmf_path = params[:measure][:hqmf].tempfile.path
    
    measure = Measures::Loader.load(hqmf_path, value_set_path, current_user, value_set_format)

    redirect_to edit_measure_url(measure)
  end

  def update
    @measure = Measure.find(params[:id])
    @measure.update_attributes!(params[:measure])
    
    redirect_to @measure, notice: 'Measure was successfully updated.'
  end

  def destroy
    @measure = Measure.find(params[:id])
    @measure.destroy

    redirect_to measures_url
  end
  
  def select_layout
    case @_action_name
    when 'show_nqf'
      "empty"
    else
      "two_columns"
    end
  end
  
  def validate_authorization!
    authorize! :manage, Measure
  end
  
  
  def definition
    measure = Measure.find(params[:id])
    render :json => measure.parameter_json
  end
  
  def export
    measure = Measure.find(params[:id])

    file = Tempfile.new(["#{measure.id}-#{Time.now.to_i}", ".zip"])
    Measures::Exporter.export(file, [measure])
    
    send_file file.path, :type => 'application/zip', :disposition => 'attachment', :filename => "measures.zip"
  end
  
  def export_all
    measures = Measure.by_user(current_user)
    
    file = Tempfile.new(["#{current_user.id}-#{Time.now.to_i}", ".zip"])
    Measures::Exporter.export(file, measures)
    
    send_file file.path, :type => 'application/zip', :disposition => 'attachment', :filename => "measures.zip"
  end
  
  def debug
    @measure = Measure.find(params[:id])
    
    # TODO: this is terrible, will refactor
    # FileUtils.mkdir_p File.join(".","tmp",'measures')
    hqmf_path = File.expand_path(File.join('.','test','fixtures','measure-defs',@measure.measure_id,"#{@measure.measure_id}.xml"))
    codes_path = File.expand_path(File.join('.','test','fixtures','measure-defs',@measure.measure_id,"#{@measure.measure_id}.xls"))
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

    # template_str = File.read(File.join('.','test','fixtures','html','test_measure.html.erb'))
    # template = ERB.new(template_str, nil, '-', "_templ_html")
    # params = {'measure_id' => filename}
    # context = ErbContext.new(params)
    # result = template.result(context.get_binding)
    # 
    # out_file = File.join(".","tmp",'measures',"#{filename}.html")
    # File.open(out_file, 'w') do |f| 
    #   f.write(result)
    # end
    # 
    # puts "wrote test html to: #{out_file}"
    
    
    # render :json => @measure.to_json
    render "measures/debug"
    
    
    
  end
  
end