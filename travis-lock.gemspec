# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'travis/lock/version'

Gem::Specification.new do |s|
  s.name         = 'travis-lock'
  s.version      = Travis::Lock::VERSION
  s.authors      = ['Travis CI']
  s.email        = 'contact@travis-ci.org'
  s.homepage     = 'https://github.com/travis-ci/travis-lock'
  s.summary      = 'Locks for use at Travis CI'
  s.description  = "#{s.summary}."
  s.licenses     = ['MIT']
  s.required_ruby_version = '~> 3.2'

  s.files        = Dir['{lib/**/*,spec/**/*,[A-Z]*}']
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
end
