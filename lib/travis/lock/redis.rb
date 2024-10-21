# frozen_string_literal: true

require 'monitor'
begin
  require 'redlock'
  require 'redis-client'
rescue LoadError
end

module Travis
  module Lock
    class Redis
      class LockError < StandardError
        attr_reader :key

        def initialize(key)
          @key = key
          super("Could not obtain lock for #{key.inspect} on Redis.")
        end
      end

      def self.clients
        @clients ||= {}
      end

      DEFAULTS = {
        ttl: 5 * 60 * 1000,
        retries: 5,
        interval: 0.1,
        timeout: 0.5,
        threads: 5
      }.freeze

      attr_reader :name, :config, :retried, :monitor

      def initialize(name, config)
        @name    = name
        @config  = DEFAULTS.merge(config)
        @retried = 0
        @monitor = Monitor.new
      end

      def exclusive
        retrying do
          client.lock(name, config[:ttl]) do |lock|
            lock ? yield(lock) : raise(LockError, name)
          end
        end
      end

      private

      def client
        monitor.synchronize do
          self.class.clients[url] ||= begin
            redis_config = RedisClient.config(url:, ssl:, ssl_params:)
            pool = redis_config.new_pool(size: config[:threads])

            Redlock::Client.new([pool], redis_timeout: config[:timeout])
          end
        end
      end

      def url
        config[:url] || raise('No Redis URL specified')
      end

      def ssl
        config[:ssl] || false
      end

      def ssl_params
        @ssl_params ||=begin
          return nil unless ssl

          value = {}
          value[:ca_path] = config[:ca_path] if config[:ca_path]
          value[:cert] = config[:cert] if config[:cert]
          value[:key] = config[:key] if config[:key]
          value[:verify_mode] =  config[:verify_mode] if config[:verify_mode]
          value
        end
      end


      def retrying
        yield
      rescue LockError
        raise if retried.to_i >= config[:retries]

        sleep config[:interval]
        @retries = retried + 1
        retry
      end
    end
  end
end
