Rails.application.routes.draw do
  get '/jobs', to: 'jobs#index'
end
