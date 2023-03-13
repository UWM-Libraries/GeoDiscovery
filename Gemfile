source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.4", ">= 7.0.4.2"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use sqlite3 as the dev and test environment database
gem "sqlite3", "~> 1.4"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.1"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :production do
  gem "mysql2"
  gem "passenger", ">= 5.0.25", require: "phusion_passenger/rack_handler"
  gem "sidekiq", "~> 7.0", ">= 7.0.6"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem "capistrano", "~> 3.17", require: false
  gem "capistrano-rails", "~> 1.6", require: false
  gem "capistrano-bundler", "~> 2.1.0"
  gem "capistrano-passenger", "~> 0.2"

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "capybara-screenshot"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webdrivers"
end
gem "blacklight", "~> 7.0"

# BL Advanced Search / Pinned to EWL bug-fix
# See: https://github.com/projectblacklight/blacklight_advanced_search/issues/127
gem "blacklight_advanced_search", git: "https://github.com/ewlarson/blacklight_advanced_search.git", branch: "bl7-fix-gentle-hands"
gem "geoblacklight", "~> 4.0"
gem "geoblacklight_sidecar_images", "~> 1.0"
gem "mini_magick", "~> 4.0"
gem "sprockets", "< 4.0"

group :development, :test do
  gem "solr_wrapper", ">= 0.3"
end
gem "rsolr", ">= 1.0", "< 3"
gem "bootstrap", "~> 4.0"
gem "twitter-typeahead-rails", "0.11.1"
gem "sassc-rails", "~> 2.1"
gem "jquery-rails"
gem "devise"
gem "devise-guests", "~> 0.8"

# ENV
gem "dotenv-rails", "~> 2.8"

# Standard
gem "standardrb"

# Cron Tasks
gem "whenever", "~> 1.0.0"
gem "sitemap_generator", "~> 6.3"

# Admin View
gem "haml"
gem "awesome_print"

# GeoCombine via the UWM Libraries Fork
gem "geo_combine", git: "https://github.com/UWM-Libraries/GeoCombine.git", branch: "main"

# ED SSH Key support
gem "ed25519", ">=1.2", "< 2.0"
gem "bcrypt_pbkdf", "~> 1.0", "< 2.0"

# ExceptionNotification
gem "exception_notification", "~> 4.5"
