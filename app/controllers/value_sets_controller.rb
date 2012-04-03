class ValueSetsController < ApplicationController
  
  load_and_authorize_resource
  
  def index
    @value_sets = ValueSet.all
  end
  
  def new
    @value_set.codes = ["99201"]
  end
  
  def show
    
  end
  
  def edit
    
  end
  
  def create
    @value_set = ValueSet.create(params[:value_set])
    
    if @value_set.persisted?
      redirect_to @value_set
    else
      flash[:error] = "Unable to create value set: #{record_error_messages}"
      render action: 'new', status: 406
    end
  end
  
  def destroy
    @value_set.destroy
    
    if @value_set.destroyed?
      redirect_to value_sets_path
    else
      flash[:error] = "Unable to destroy value set"
      redirect_to value_sets_path, status: 406
    end
  end
  
  def update
    if @value_set.update_attributes(params[:value_set])
      redirect_to @value_set
    else  
      flash[:error] = "Unable to update value set: #{record_error_messages}"
      render action: 'edit', status: 406
    end
  end
  
  private
  
  def record_error_messages
    @value_set.errors.full_messages.join(', ')
  end
end
