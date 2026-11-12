require 'rails_helper'

describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    before :each do
      @fake_results = [double('movie1'), double('movie2')]
    end

    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).
        with({ title: 'hardware', release_year: '', language: 'all' }).
        and_return(@fake_results)
      get :search_tmdb, params: { title: 'hardware' }
    end

    it 'passes the release year and language to the model method' do
      expect(Movie).to receive(:find_in_tmdb).
        with({ title: 'Manhunter', release_year: '1986', language: 'en' }).
        and_return(@fake_results)
      get :search_tmdb, params: { title: ' Manhunter ', release_year: '1986', language: 'en' }
    end

    describe 'after valid search' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb).and_return(@fake_results)
        get :search_tmdb, params: { title: 'hardware' }
      end

      it 'selects the Search Results template for rendering' do
        expect(response).to render_template('search_tmdb')
      end

      it 'makes the TMDb search results available to that template' do
        expect(assigns(:movies)).to eq(@fake_results)
      end

      it 'does not display an error message' do
        expect(flash[:danger]).to be_nil
      end
    end

    describe 'when the search form has not been submitted yet' do
      before :each do
        expect(Movie).not_to receive(:find_in_tmdb)
        get :search_tmdb
      end

      it 'renders the search form' do
        expect(response).to render_template('search_tmdb')
      end

      it 'does not display an error message' do
        expect(flash[:danger]).to be_nil
      end

      it 'does not make any search results available' do
        expect(assigns(:movies)).to be_nil
      end
    end

    describe 'when the title is missing' do
      ['', '   '].each do |title|
        it "does not search TMDb and asks for the required fields (title #{title.inspect})" do
          expect(Movie).not_to receive(:find_in_tmdb)
          get :search_tmdb, params: { title: title, release_year: '1986', language: 'all' }
          expect(flash[:danger]).to eq('Please fill in all required fields!')
          expect(assigns(:movies)).to be_nil
          expect(response).to render_template('search_tmdb')
        end
      end
    end

    describe 'when no movies match' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb).and_return([])
        get :search_tmdb, params: { title: 'qwertyuiopasdfgh' }
      end

      it 'displays a no movies found message' do
        expect(flash[:danger]).to eq('No movies found with given parameters!')
      end

      it 'renders the search template' do
        expect(response).to render_template('search_tmdb')
      end
    end
  end

  describe 'adding a movie from TMDb' do
    let(:movie_attributes) do
      { title: 'Manhunter', rating: 'R', release_date: '1986-08-15', description: 'A former FBI profiler...' }
    end

    it 'saves the movie to the database' do
      expect { post :add_movie, params: { movie: movie_attributes } }.to change(Movie, :count).by(1)
      movie = Movie.last
      expect(movie.title).to eq('Manhunter')
      expect(movie.rating).to eq('R')
      expect(movie.release_date.to_date).to eq(Date.new(1986, 8, 15))
      expect(movie.description).to eq('A former FBI profiler...')
    end

    it 'redirects to the search page' do
      post :add_movie, params: { movie: movie_attributes }
      expect(response).to redirect_to(search_tmdb_path)
    end

    it 'displays a success message' do
      post :add_movie, params: { movie: movie_attributes }
      expect(flash[:success]).to eq('Manhunter was successfully added to RottenPotatoes.')
    end

    it 'defaults the rating to R when it is missing or invalid' do
      post :add_movie, params: { movie: movie_attributes.merge(rating: 'XYZ') }
      expect(Movie.last.rating).to eq('R')
    end

    it 'saves a movie that has no release date' do
      post :add_movie, params: { movie: movie_attributes.merge(release_date: '') }
      expect(Movie.last.release_date).to be_nil
    end

    it 'does not save a movie without a title' do
      expect { post :add_movie, params: { movie: movie_attributes.merge(title: ' ') } }.not_to change(Movie, :count)
      expect(flash[:danger]).to eq('Please fill in all required fields!')
      expect(response).to redirect_to(search_tmdb_path)
    end

    it 'does not crash when no movie parameters are given' do
      expect { post :add_movie }.not_to change(Movie, :count)
      expect(response).to redirect_to(search_tmdb_path)
    end
  end
end
