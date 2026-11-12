class MoviesController < ApplicationController
  before_action :force_index_redirect, only: [:index]

  def show
    id = params[:id] # retrieve movie ID from URI route
    @movie = Movie.find(id) # look up movie by unique ID
    # will render app/views/movies/show.<extension> by default
  end

  def index
    @all_ratings = Movie.all_ratings
    @movies = Movie.with_ratings(ratings_list, sort_by)
    @ratings_to_show_hash = ratings_hash
    @sort_by = sort_by
    # remember the correct settings for next time
    session['ratings'] = ratings_list
    session['sort_by'] = @sort_by
  end

  def new
    # default: render 'new' template
  end

  def create
    @movie = Movie.create!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully created."
    redirect_to movies_path
  end

  def edit
    @movie = Movie.find params[:id]
  end

  def update
    @movie = Movie.find params[:id]
    @movie.update!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully updated."
    redirect_to movie_path(@movie)
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end

  def search_tmdb
    @search_terms = search_terms
    # just show the empty search form until the user actually submits a search
    return unless params.key?(:title)

    if @search_terms[:title].blank?
      flash.now[:danger] = 'Please fill in all required fields!'
      return
    end

    @movies = Movie.find_in_tmdb(@search_terms)
    flash.now[:danger] = 'No movies found with given parameters!' if @movies.blank?
  end

  def add_movie
    attributes = add_movie_params
    if attributes[:title].blank?
      flash[:danger] = 'Please fill in all required fields!'
    else
      attributes[:rating] = Movie::DEFAULT_RATING unless Movie.all_ratings.include?(attributes[:rating])
      movie = Movie.create!(attributes)
      flash[:success] = "#{movie.title} was successfully added to RottenPotatoes."
    end
    redirect_to search_tmdb_path
  end

  private

  def movie_params
    params.require(:movie).permit(:title, :rating, :description, :release_date)
  end

  def add_movie_params
    movie = params[:movie]
    movie = ActionController::Parameters.new({}) unless movie.is_a?(ActionController::Parameters)
    attributes = movie.permit(:title, :rating, :description, :release_date).to_h.symbolize_keys
    attributes[:title] = attributes[:title].to_s.strip
    attributes[:release_date] = attributes[:release_date].presence
    attributes
  end

  def search_terms
    {
      title: params[:title].to_s.strip,
      release_year: params[:release_year].to_s.strip,
      language: params[:language].presence || 'all'
    }
  end

  def force_index_redirect
    return unless !params.key?(:ratings) || !params.key?(:sort_by)

    flash.keep
    url = movies_path(sort_by: sort_by, ratings: ratings_hash)
    redirect_to url
  end

  def ratings_list
    params[:ratings]&.keys || session[:ratings] || Movie.all_ratings
  end

  def ratings_hash
    ratings_list.to_h { |item| [item, "1"] }
  end

  def sort_by
    params[:sort_by] || session[:sort_by] || 'id'
  end
end
