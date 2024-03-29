# frozen_string_literal: true

begin
  require 'active_record'

  ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    database: 'travis_test',
    pool: 50
  )
rescue LoadError
end
