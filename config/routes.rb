Rails.application.routes.draw do
  get 'races/:id' => 'races#show'
  get 'races/:id/most_recent' => 'races#most_recent'
  get 'karts' => 'karts#index'
  get 'hours' => 'hours#index'
  get 'competetive' => 'competetive#index'

  get '/', to: redirect('/races/latest')
end
