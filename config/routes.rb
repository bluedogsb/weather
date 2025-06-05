Rails.application.routes.draw do
  # Root route for the weather form
  get '/weather', to: 'weather#index', as: :weather
  root 'weather#index'

  namespace :api do
    namespace :v1 do
      get "weather/forecast", to: "weather#forecast"
    end
  end
end
