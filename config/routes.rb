Bonnie::Application.routes.draw do
  
  resources :measures do
    member do
      get :export
      get :definition
      get :import_resource
      post :publish
      get :show_nqf
      get :debug  # measure debug page
      get :test   # select patients form
      post :test  # handle select patients form
    end
    collection do
      get :published
      get :export_all
    end
  end

  devise_for :users, :controllers => {:registrations => "registrations"}
  
  root :to => 'measures#index'
  
  resources :value_sets
  
  # FIXME: too nested, don't have another option right now - cdillon
  # one-off debug url with measure and patient ids
  match 'measures/:measure_id/debug/:record_id' => 'Measures#debug', :as => :debug_measure

 end
