class MeasuresController < ApplicationController
  
  layout :select_layout
  before_filter :authenticate_user!
  before_filter :validate_authorization!

  add_breadcrumb 'measures', ""
  
  rescue_from Mongoid::Errors::Validations do
    render :template => "measures/edit"
  end
  
  def index
    @measures = current_user.measures
  end

  def show
    @measure = Measure.find(params[:id])
  end

  def import_resource
  
  end
  
  def publish
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
    @measure = Measure.find(params[:id])
  end

  def create
    measure = Measure.new
    
    # Meta data
    measure.user = current_user
    measure.endorser = params[:measure][:endorser]
    measure.measure_id = params[:measure][:measure_id]
    measure.title = params[:measure][:title]
    measure.description = params[:measure][:description]
    measure.category = params[:measure][:category]
    measure.steward = params[:measure][:steward]
    
    # Value sets
    value_set_file = params[:measure][:value_sets]
    value_set_parser = HQMF::ValueSet::Parser.new()
    value_sets = value_set_parser.parse(value_set_file.tempfile.path, {format: value_set_parser.get_format(value_set_file.original_filename)})
    value_sets.each do |value_set|
      set = ValueSet.new(value_set)
      set.measure = measure
      set.save!
    end
    
    # Parsed HQMF
    if params[:measure][:hqmf]
      hqmf_contents = Nokogiri::XML(params[:measure][:hqmf].open).to_s
      hqmf = HQMF::Parser.parse(hqmf_contents, HQMF::Parser::HQMF_VERSION_1)
      json = hqmf.to_json
      
      measure.population_criteria = json[:population_criteria]
      measure.data_criteria = json[:data_criteria]
      measure.measure_period = json[:measure_period]
    end
    
    measure.save!
    redirect_to measure_url(measure)
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
    "two_columns"
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
    
    file = Tempfile.new("measures-#{Time.now.to_i}")
    Measures::Exporter.export(file, [measure])
    
    send_file file.path, :type => 'application/zip', :disposition => 'attachment', :filename => "measures.zip"
  end
end