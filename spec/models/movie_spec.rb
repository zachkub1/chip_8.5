require 'spec_helper'
require 'rails_helper'

describe Movie do
  describe 'searching TMDB by keyword' do
    let(:tmdb_url) { %r{api\.themoviedb\.org/3/search/movie} }

    def stub_tmdb(results, status: 200)
      stub_request(:get, tmdb_url).
        to_return(status: status, body: JSON.generate({ page: 1, results: results }), headers: {})
    end

    it 'calls Faraday gem' do
      expect(Faraday).to receive(:get)
      Movie.find_in_tmdb({ title: 'hacker', language: 'en' })
    end

    it 'calls TMDb with valid API key' do
      Movie.find_in_tmdb({ title: 'hacker', language: 'en' }, 'my_api_key')
      expect(a_request(:get, tmdb_url).with(query: hash_including('api_key' => 'my_api_key'))).to have_been_made
    end

    it 'uses the TMDB_API_KEY environment variable by default' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('TMDB_API_KEY', nil).and_return('env_key')
      Movie.find_in_tmdb({ title: 'hacker' })
      expect(a_request(:get, tmdb_url).with(query: hash_including('api_key' => 'env_key'))).to have_been_made
    end

    it 'sends the title as the query' do
      Movie.find_in_tmdb({ title: 'This Life + 10' }, 'key')
      expect(a_request(:get, tmdb_url).with(query: hash_including('query' => 'This Life + 10'))).to have_been_made
    end

    it 'sends the release year when it is given' do
      Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000' }, 'key')
      expect(a_request(:get, tmdb_url).with(query: hash_including('year' => '2000'))).to have_been_made
    end

    it 'does not send a release year when it is blank' do
      Movie.find_in_tmdb({ title: 'Olympics', release_year: '' }, 'key')
      expect(a_request(:get, tmdb_url).with(query: hash_excluding('year'))).to have_been_made
    end

    it 'sends an English language parameter when English only is chosen' do
      Movie.find_in_tmdb({ title: 'Olympics', language: 'en' }, 'key')
      expect(a_request(:get, tmdb_url).with(query: hash_including('language' => 'en-US'))).to have_been_made
    end

    it 'does not send a language parameter when all languages are chosen' do
      Movie.find_in_tmdb({ title: 'Olympics', language: 'all' }, 'key')
      expect(a_request(:get, tmdb_url).with(query: hash_excluding('language'))).to have_been_made
    end

    it 'accepts a plain title string' do
      expect(Movie.find_in_tmdb('Olympics', 'key').size).to eq(2)
    end

    describe 'with a successful response' do
      before :each do
        @movies = Movie.find_in_tmdb({ title: 'Olympics', release_year: '2000', language: 'all' }, 'key')
      end

      it 'returns a Movie for every result' do
        expect(@movies.size).to eq(2)
        expect(@movies).to all(be_a(Movie))
      end

      it 'returns movies that have not been saved to the database' do
        expect(@movies.none?(&:persisted?)).to be true
        expect(Movie.count).to eq(0)
      end

      it 'fills in the title, release date and description' do
        movie = @movies.first
        expect(movie.title).to eq('Sydney 2000 Olympics Opening Ceremony')
        expect(movie.release_date.to_date).to eq(Date.new(2000, 9, 15))
        expect(movie.description).to start_with('Coverage of the glorious Olympic Opening Ceremony')
      end

      it 'rates every movie R' do
        expect(@movies.map(&:rating)).to all(eq('R'))
      end
    end

    describe 'filtering results' do
      let(:results) do
        [
          { title: 'Amelie', original_language: 'fr', release_date: '2001-04-25', overview: 'Paris' },
          { title: 'Manhunter', original_language: 'en', release_date: '1986-08-15', overview: 'FBI' }
        ]
      end

      before(:each) { stub_tmdb(results) }

      it 'only returns English-language movies when English only is chosen' do
        movies = Movie.find_in_tmdb({ title: 'x', language: 'en' }, 'key')
        expect(movies.map(&:title)).to eq(['Manhunter'])
      end

      it 'returns movies in every language when all languages are chosen' do
        movies = Movie.find_in_tmdb({ title: 'x', language: 'all' }, 'key')
        expect(movies.map(&:title)).to eq(%w[Amelie Manhunter])
      end

      it 'leaves out movies already in the RottenPotatoes database' do
        Movie.create!(title: 'Manhunter', rating: 'R', release_date: '1986-08-15')
        movies = Movie.find_in_tmdb({ title: 'x' }, 'key')
        expect(movies.map(&:title)).to eq(['Amelie'])
      end

      it 'keeps a movie whose title matches a saved movie released on a different date' do
        Movie.create!(title: 'Manhunter', rating: 'R', release_date: '2017-01-01')
        movies = Movie.find_in_tmdb({ title: 'x' }, 'key')
        expect(movies.map(&:title)).to eq(%w[Amelie Manhunter])
      end
    end

    describe 'with unusual results' do
      it 'handles a missing release date and overview' do
        stub_tmdb([{ title: 'Unknown', release_date: '', overview: nil }])
        movie = Movie.find_in_tmdb({ title: 'Unknown' }, 'key').first
        expect(movie.release_date).to be_nil
        expect(movie.description).to be_nil
      end

      it 'handles an invalid release date' do
        stub_tmdb([{ title: 'Unknown', release_date: 'not-a-date' }])
        expect(Movie.find_in_tmdb({ title: 'Unknown' }, 'key').first.release_date).to be_nil
      end

      it 'skips results without a title' do
        stub_tmdb([{ title: '' }, { overview: 'no title' }, { title: 'Real' }])
        expect(Movie.find_in_tmdb({ title: 'x' }, 'key').map(&:title)).to eq(['Real'])
      end
    end

    describe 'returns no movies' do
      it 'when TMDb finds no matches' do
        stub_tmdb([])
        expect(Movie.find_in_tmdb({ title: 'qwertyuiop' }, 'key')).to eq([])
      end

      it 'when the API key is invalid' do
        stub_request(:get, tmdb_url).to_return(
          status: 401,
          body: JSON.generate({ success: false, status_code: 7, status_message: 'Invalid API key' })
        )
        expect(Movie.find_in_tmdb({ title: 'Olympics' }, 'bad_key')).to eq([])
      end

      it 'when TMDb returns something that is not JSON' do
        stub_request(:get, tmdb_url).to_return(status: 200, body: '<html>oops</html>')
        expect(Movie.find_in_tmdb({ title: 'Olympics' }, 'key')).to eq([])
      end

      it 'when TMDb returns JSON without a results list' do
        stub_request(:get, tmdb_url).to_return(status: 200, body: JSON.generate({ results: 'nope' }))
        expect(Movie.find_in_tmdb({ title: 'Olympics' }, 'key')).to eq([])
      end

      it 'when TMDb cannot be reached' do
        stub_request(:get, tmdb_url).to_timeout
        expect(Movie.find_in_tmdb({ title: 'Olympics' }, 'key')).to eq([])
      end

      it 'when the title is blank, without calling TMDb' do
        expect(Movie.find_in_tmdb({ title: '  ' }, 'key')).to eq([])
        expect(a_request(:get, tmdb_url)).not_to have_been_made
      end

      it 'when the release year is not a number, without calling TMDb' do
        expect(Movie.find_in_tmdb({ title: 'Olympics', release_year: 'abcd' }, 'key')).to eq([])
        expect(a_request(:get, tmdb_url)).not_to have_been_made
      end
    end
  end

  describe 'filtering by rating' do
    before :each do
      Movie.create!(title: 'Aladdin', rating: 'G', release_date: '1992-11-25')
      Movie.create!(title: 'The Terminator', rating: 'R', release_date: '1984-10-26')
    end

    it 'returns only movies with the given ratings' do
      expect(Movie.with_ratings(['r'], 'title').map(&:title)).to eq(['The Terminator'])
    end

    it 'returns all movies when no ratings are given' do
      expect(Movie.with_ratings(nil, 'title').map(&:title)).to eq(['Aladdin', 'The Terminator'])
    end
  end
end
