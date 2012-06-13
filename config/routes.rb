Bonnie::Application.routes.draw do

  # one-off debug url with measure and patient ids FIXME: too nested - cdillon
  
  
  resources :measures do
    member do
      get :export
      get :import_resource
      post :publish
      get :show_nqf
      match :add_criteria
      match :update_criteria
      get :debug  # measure debug page
      get :test   # select patients form
      get 'debug/:record_id' => 'Measures#debug', :as => :debug_measure
      post :test  # handle select patients form
    end
    collection do
      get :published
      get :export_all
    end
  end

  get 'measures/:id/:population' => 'measures#show', :constraints => {:population => /\d+/}
  get 'measures/:id/definition' => 'measures#definition'
  get 'measures/:id/:population/definition' => 'measures#definition'

  devise_for :users, :controllers => {:registrations => "registrations"}

  root :to => 'measures#index'

  resources :value_sets

 end
