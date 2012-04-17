class MeasuresController < ApplicationController
  
  layout :select_layout
  before_filter :authenticate_user!
  load_and_authorize_resource

  add_breadcrumb 'measures', ""
  
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
    #value_sets = params[:value_sets]
    #hqmf = HQMF::Document.new(params[:hqmf])
    
    #hqmf_contents = File.open(params[:hqmf].tempfile).read
    #converter = Generator::JS.new(hqmf_contents)
    #converted_hqmf = "#{converter.js_for_data_criteria}\n#{converter.js_for('IPP')}\n#{converter.js_for('DENOM')}\n#{converter.js_for('NUMER')}\n#{converter.js_for('DENEXCEP')}"
    
    #binding.pry
    
    measure = Measure.new
    measure.user = current_user
    measure.endorser = params[:endorser]
    measure.measure_id = params[:measure_id]
    measure.title = params[:title]
    measure.description = params[:description]
    measure.category = params[:category]
    measure.steward = params[:steward]
    measure.save
    
    redirect_to measure_url(measure)
  end

  def update
    @measure = Measure.find(params[:id])

    if @measure.update_attributes(params[:measure])
      redirect_to @measure, notice: 'Measure was successfully updated.'
    else
      render action: "edit"
    end
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
