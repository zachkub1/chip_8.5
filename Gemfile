source 'https://rubygems.org'

gem 'rails', '~> 7.1.5'
gem 'sprockets-rails'
gem 'faraday'
gem 'jquery-rails'

# for Heroku deployment - as described in Ap. A of ELLS book
group :development, :test do
  gem 'debug'
  gem 'database_cleaner'
  gem 'cucumber-rails', require: false
  gem 'rspec-rails'
  gem 'mechanize', '~> 2.10', '>= 2.10.1'

  # Use sqlite3 as the database for Active Record
  gem 'sqlite3', '>= 1.4'
  gem 'webmock'
  gem 'web-console'
  gem 'simplecov'
end

group :test do
  gem 'rails-controller-testing'
  gem 'guard-rspec'
end

group :production do
  gem 'pg', '~> 1.5'
end

# Required for timezone support on Linux (Gradescope)
gem 'tzinfo-data'