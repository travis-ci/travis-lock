require 'active_record'
require 'travis/lock'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'travis_development',
  pool: 30
)

class Lock
  class Redis
    def exclusive(&block)
      options = {
        strategy: :redis,
        url: 'redis://localhost:6379'
      }
      Travis::Lock.exclusive('test', options, &block)
    end
  end

  class Postgresql
    def exclusive(&block)
      options = {
        strategy: :postgresql,
        # try: true,
        try: false,
        transactional: false
      }
      Travis::Lock.exclusive('test', options, &block)
    end
  end
end

number_of_runs = Integer(ARGV[0] || 1)
concurrency    = Integer(ARGV[1] || 20)
lock_types     = ARGV[2] ? [ARGV[2].to_sym] : Lock.constants

1.upto(number_of_runs) do |ix|
  lock_types.each do |strategy|
    puts "#{ix} Using strategy #{strategy}"
    lock  = Lock.const_get(strategy).new
    count = 0

    threads = (1..concurrency).to_a.map do
      Thread.new do
        lock.exclusive do
          count = count.tap { sleep(rand(0.001..0.009)) } + 1
        end
      end
    end
    threads.map(&:join)

    puts "  #{count == concurrency ? "\033[32;1m" : "\033[31;1m" }Expected count to be #{concurrency}. Actually is #{count}.\033[0m\n\n"
  end
end
