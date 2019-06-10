source 'https://rubygems.org'
ruby '~> 2.6.0'

gem 'aws-sdk'
gem 'chromedriver-helper'
gem 'dotenv-rails', groups: [:development, :test]
gem 'nokogiri'
gem 'rubyXL'
gem 'watir'

# App server
gem 'rails', '~> 5.1.4'

# Database
gem 'pg', '~> 0.21'

# Web server
gem 'puma'

# Assets
gem 'sass-rails'
gem 'uglifier'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
