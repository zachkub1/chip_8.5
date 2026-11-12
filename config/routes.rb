Rottenpotatoes::Application.routes.draw do
  resources :movies
  # search TMDb for movies and add them to RottenPotatoes
  get '/search', to: 'movies#search_tmdb', as: 'search_tmdb'
  post '/add_movie', to: 'movies#add_movie', as: 'add_movie'
  # map '/' to be a redirect to '/movies'
  root to: redirect('/movies')
end
