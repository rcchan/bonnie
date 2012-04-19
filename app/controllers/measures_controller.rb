class MeasuresController < ApplicationController
  
  layout :select_layout
  before_filter :authenticate_user!
  load_and_authorize_resource

  add_breadcrumb 'measures', ""
  
  rescue_from Mongoid::Errors::Validations do
    render :template => "measures/edit"
  end
  
  def index
    @measures = current_user.measures
  end

  def show
    @measure = Measure.find(params[:id])
    
    #hqmf_contents = File.open(params[:hqmf].tempfile).read
    #converter = Generator::JS.new(hqmf_contents)
    #converted_hqmf = "#{converter.js_for_data_criteria}\n#{converter.js_for('IPP')}\n#{converter.js_for('DENOM')}\n#{converter.js_for('NUMER')}\n#{converter.js_for('DENEXCEP')}"
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
    
    measure.user = current_user
    measure.endorser = params[:endorser]
    measure.measure_id = params[:measure_id]
    measure.title = params[:title]
    measure.description = params[:description]
    measure.category = params[:category]
    measure.steward = params[:steward]
    
    value_sets = params[:value_sets]
    
    if params[:hqmf]
      #hqmf = HQMF::Parser.parse(File.open(params[:hqmf]).read, HQMF::Parser::HQMF_VERSION_1).
      hqmf = HQMF1::Document.new(File.open(params[:hqmf]).read)
      json = hqmf.to_json
      
      measure.population_criteria = json[:logic]
      measure.data_criteria = json[:data_criteria]
      measure.measure_period = json[:attributes]
    end
    
    measure.save
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
  
  def definition
    render :json => 'Hoohah'
  end
end