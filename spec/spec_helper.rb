# frozen_string_literal: true

ENV['ENV'] = 'test'

require 'mocha'
require 'travis/lock'
require 'support/database'

RSpec.configure do |config|
  config.mock_with :mocha
end
