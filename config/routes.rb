Rails.application.routes.draw do
  get 'karts/index'
  get 'races/:id' => 'races#show'

  root 'karts#index'
end
