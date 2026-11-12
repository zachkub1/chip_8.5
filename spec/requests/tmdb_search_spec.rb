require 'rails_helper'

describe 'Searching TMDb and adding movies', type: :request do
  it 'links to the search page from the home page' do
    get movies_path(sort_by: 'id', ratings: { 'G' => '1' })
    expect(response.body).to include(search_tmdb_path)
  end

  it 'shows the search form with a link back to the movie list' do
    get search_tmdb_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="tmdb_form"')
    expect(response.body).to include('Back to movie list')
    expect(response.body).not_to include('id="search_movies"')
    expect(response.body).not_to include('Please fill in all required fields!')
  end

  it 'shows an error and no results table when the title is missing' do
    get search_tmdb_path, params: { title: '', release_year: '2000', language: 'all' }
    expect(response.body).to include('Please fill in all required fields!')
    expect(response.body).to include('alert-danger')
    expect(response.body).not_to include('id="search_movies"')
  end

  it 'shows a message when no movies are found' do
    stub_request(:get, /api.themoviedb.org/).
      to_return(status: 200, body: JSON.generate({ page: 1, results: [] }))
    get search_tmdb_path, params: { title: 'qwertyuiop', release_year: '', language: 'all' }
    expect(response.body).to include('No movies found with given parameters!')
    expect(response.body).not_to include('id="search_movies"')
  end

  it 'shows the matching movies in a table with an Add movie button for each' do
    get search_tmdb_path, params: { title: 'Olympics', release_year: '2000', language: 'all' }
    expect(response.body).to include('id="search_movies"')
    expect(response.body).to include('Sydney 2000 Olympics Opening Ceremony')
    expect(response.body).to include('Sydney 2000 Olympics Closing Ceremony')
    expect(response.body.scan('value="Add movie"').size).to eq(2)
    expect(response.body).to include(%(action="#{add_movie_path}"))
  end

  it 'adds a movie and shows it on the home page, then leaves it out of later searches' do
    post add_movie_path, params: {
      movie: { title: 'Sydney 2000 Olympics Opening Ceremony', rating: 'R',
               release_date: '2000-09-15', description: 'Coverage' }
    }
    expect(response).to redirect_to(search_tmdb_path)
    follow_redirect!
    expect(response.body).to include('Sydney 2000 Olympics Opening Ceremony was successfully added to RottenPotatoes.')
    expect(response.body).to include('alert-success')

    get movies_path(sort_by: 'id', ratings: { 'R' => '1' })
    expect(response.body).to include('Sydney 2000 Olympics Opening Ceremony')

    get search_tmdb_path, params: { title: 'Olympics', release_year: '2000', language: 'all' }
    expect(response.body).not_to include('Sydney 2000 Olympics Opening Ceremony')
    expect(response.body).to include('Sydney 2000 Olympics Closing Ceremony')
  end

  it 'shows the details page of a movie added without a release date' do
    movie = Movie.create!(title: 'Undated', rating: 'R', release_date: nil)
    get movie_path(movie)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Undated')
  end
end
