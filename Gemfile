source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails](https://github.com/rails/sprockets-rails)
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma](https://github.com/puma/puma)
gem "puma", "~> 7.1"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails](https://github.com/rails/importmap-rails)
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev](https://turbo.hotwired.dev)
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev](https://stimulus.hotwired.dev)
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder](https://github.com/rails/jbuilder)
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 5.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis](https://github.com/rails/kredis)
# gem "kredis"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images)
# gem "image_processing", "~> 1.2"

group :development do
  # Use the Listen gem to watch for file changes and reload the server
  gem "listen", "~> 3.9"

  # Speed up commands on slow terminals, or on legacy Windows systems
  # gem "ffi", github: "ffi/ffi", branch: "main"

  # Display deprecation notices to development environment
  gem "rubocop-rails-omakase", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing](https://guides.rubyonrails.org/testing.html#system-testing)
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Use SQLite for local development
group :development, :test do
  gem "sqlite3", "~> 2.1"
end

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
gem 'devise'
gem 'devise'
