Rails.application.routes.draw do
  get "pages/terms"
  get "pages/privacy"
  root "home#index"

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  get "terms", to: "pages#terms"
  get "privacy", to: "pages#privacy"

  post "/guests/login", to: "guests#login", as: :guests_login

  resources :praises, only: [ :index, :create ]
  resources :logs do
    collection do
      get :calendar
    end
  end
end
