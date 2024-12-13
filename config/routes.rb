require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resources :products
  resource :cart, only: [:show, :create] do
    post 'add_items', to: 'carts#add_item'
  end
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
