Bonnie::Application.routes.draw do

  resources :measures do
    member do
      get :export
      get :import_resource
      post :publish
      get :show_nqf
      get :debug
      match :add_criteria
      match :update_criteria
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
