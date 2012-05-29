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
    @all_published = Measure.published
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

    @show_published=true
    @measures = current_user.measures
    @all_published = Measure.published

    flash[:notice] = "Published #{@measure.title}."
    render :index
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

  def add_criteria
    @measure = Measure.find(params[:id])
    @measure.add_data_criteria({
      "id" => params[:criteria_id],
      "title" => params[:title],
      "description" => params[:description],
      "standard_category" => params[:standard_category],
      "code_list_id" => params[:code_list_id],
      "property" => params[:property],
      "type" => params[:type]
    })
    render :json => @measure if @measure.save
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
      "measure_page"
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
    render "measures/debug"
  end

end
