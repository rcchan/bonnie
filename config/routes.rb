Bonnie::Application.routes.draw do

  resources :measures do
    member do
      get :export
      get :definition
      get :import_resource
      post :publish
      get :show_nqf
      get :debug
      match :add_criteria
    end
    collection do
      get :published
      get :export_all
    end
  end

  devise_for :users, :controllers => {:registrations => "registrations"}

  root :to => 'measures#index'

  resources :value_sets

 end
