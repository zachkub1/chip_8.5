class Movie < ApplicationRecord
  TMDB_SEARCH_URL = 'https://api.themoviedb.org/3/search/movie'.freeze
  # TMDb search results don't include an MPAA rating, so default to the safest one
  DEFAULT_RATING = 'R'.freeze

  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end

  # Search TMDb and return a list of (unsaved) Movie objects that are not
  # already in the RottenPotatoes database.
  #
  # search_terms is either a title string or a hash with the keys
  # :title (required), :release_year (optional) and :language ('en' or 'all').
  def self.find_in_tmdb(search_terms, api_key = ENV.fetch('TMDB_API_KEY', nil))
    terms = normalize_search_terms(search_terms)
    return [] if terms[:title].blank?
    return [] if terms[:release_year].present? && terms[:release_year] !~ /\A\d{1,4}\z/

    results = tmdb_results(tmdb_query_params(terms, api_key))
    results = results.select { |r| r['original_language'] == 'en' } if terms[:language] == 'en'
    movies = results.map { |result| from_tmdb(result) }
    reject_existing(movies)
  end

  def self.normalize_search_terms(search_terms)
    terms = search_terms.respond_to?(:to_h) ? search_terms.to_h : { title: search_terms }
    terms = terms.transform_keys(&:to_sym)
    {
      title: terms[:title].to_s.strip,
      release_year: terms[:release_year].to_s.strip,
      language: terms[:language].to_s.strip
    }
  end

  def self.tmdb_query_params(terms, api_key)
    query = { api_key: api_key, query: terms[:title] }
    query[:year] = terms[:release_year] if terms[:release_year].present?
    query[:language] = 'en-US' if terms[:language] == 'en'
    query
  end

  # Returns the array of raw result hashes, or [] if anything went wrong
  def self.tmdb_results(query)
    response = Faraday.get(TMDB_SEARCH_URL, query)
    return [] unless response.respond_to?(:success?) && response.success?

    body = JSON.parse(response.body)
    results = body.is_a?(Hash) ? body['results'] : nil
    results.is_a?(Array) ? results.select { |r| r.is_a?(Hash) && r['title'].present? } : []
  rescue Faraday::Error, JSON::ParserError
    []
  end

  def self.from_tmdb(result)
    Movie.new(
      title: result['title'],
      rating: DEFAULT_RATING,
      release_date: parse_date(result['release_date']),
      description: result['overview'].presence
    )
  end

  def self.parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def self.reject_existing(movies)
    return movies if movies.empty?

    saved = where(title: movies.map(&:title).uniq).pluck(:title, :release_date)
    saved_keys = saved.map { |title, date| [title, date&.to_date] }
    movies.reject { |movie| saved_keys.include?([movie.title, movie.release_date&.to_date]) }
  end

  private_class_method :normalize_search_terms, :tmdb_query_params, :tmdb_results,
                       :from_tmdb, :parse_date, :reject_existing
end
