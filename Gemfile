# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'activerecord', '~> 7'
gem 'redlock'

platform :ruby do
  gem 'pg'
end

group :test do
  gem 'mocha', '~> 2.0'
  gem 'rspec', '~> 3.12'
end

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
