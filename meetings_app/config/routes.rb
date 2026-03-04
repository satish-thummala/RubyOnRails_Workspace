Rails.application.routes.draw do
  root "sessions#new"

  get    "/login",   to: "sessions#new",     as: :login
  post   "/login",   to: "sessions#create"
  delete "/logout",  to: "sessions#destroy",  as: :logout

  get  "/signup", to: "users#new",    as: :signup
  post "/signup", to: "users#create"

  get "/profile", to: "users#show", as: :user

  get "/dashboard", to: "dashboard#index", as: :dashboard
end
