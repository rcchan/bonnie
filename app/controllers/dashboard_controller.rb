class DashboardController < ApplicationController
  
  layout :select_layout
  
  before_filter :authenticate_user!
  before_filter :validate_authorization!
  
  def index
    
  end
  
  def validate_authorization!
    authorize! :read, :dashboard
  end


  def select_layout
    "two_columns"
  end
  
end
