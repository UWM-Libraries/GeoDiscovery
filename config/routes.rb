# frozen_string_literal: true

Rails.application.routes.draw do
  get "robots.:format" => "robots#robots"

  mount Blacklight::Engine => "/"
  mount BlacklightAdvancedSearch::Engine => "/"

  root to: "catalog#index"
  concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: "catalog", path: "/catalog", controller: "catalog" do
    concerns :searchable
  end

  get "/catalog/:id/admin" => "catalog#admin", :as => "admin_catalog"

  devise_for :users

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete "clear"
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  mount Geoblacklight::Engine => "geoblacklight"
  concern :gbl_exportable, Geoblacklight::Routes::Exportable.new
  resources :solr_documents, only: [:show], path: "/catalog", controller: "catalog" do
    concerns :gbl_exportable
  end
  concern :gbl_wms, Geoblacklight::Routes::Wms.new
  namespace :wms do
    concerns :gbl_wms
  end
  concern :gbl_downloadable, Geoblacklight::Routes::Downloadable.new
  namespace :download do
    concerns :gbl_downloadable
  end
  resources :download, only: [:show]
mount Blacklight::Allmaps::Engine => '/'
end
