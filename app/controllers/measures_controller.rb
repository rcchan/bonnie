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
    @measure = Measure.new(params[:measure])
    @measure.user = current_user

    if @measure.save
      redirect_to :action => "import_resource", :id => @measure.id
    else
      render action: "new" 
    end
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
  
end
