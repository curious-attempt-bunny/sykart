Rails.application.routes.draw do
  get 'races/:id' => 'races#show'
  get 'karts' => 'karts#index'

  get '/', to: redirect('/races/latest')
end
