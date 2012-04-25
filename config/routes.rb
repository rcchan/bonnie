Bonnie::Application.routes.draw do
  
  resources :measures do
    member do
      get :definition
      get :export
      get :import_resource
      post :publish
    end
    collection do
      get :published
    end
  end

  devise_for :users, :controllers => {:registrations => "registrations"}
  
  root :to => 'measures#index'
  
  resources :value_sets

 end
