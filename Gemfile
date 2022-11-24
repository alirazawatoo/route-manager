source 'https://rubygems.org'

ruby '~> 3.4.0'

gem 'rails', '~> 8.1.4'
gem 'puma', '>= 6.0'
gem 'tzinfo-data', platforms: %i[windows jruby]

gem 'geocoder'
gem 'httparty'

group :development, :test do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'rspec-rails', '~> 8.0'
  gem 'rubocop-rails-omakase', require: false
end

group :test do
  gem 'timecop'
  gem 'vcr', '~> 6.3'
  gem 'webmock'
end
