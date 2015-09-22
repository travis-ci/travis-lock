require 'monitor'
begin
  require 'redlock'
rescue LoadError
end

module Travis
  module Lock
    class Redis
      class LockError < StandardError
        def initialize(key)
          super("Could not obtain lock for #{key.inspect} on Redis.")
        end
      end

      extend MonitorMixin

      DEFAULTS = {
        ttl:      5 * 60,
        retries:  5,
        interval: 0.1
      }

      attr_reader :name, :config, :retried

      def initialize(name, config)
        @name    = name
        @config  = DEFAULTS.merge(config)
        @retried = 0
      end

      def exclusive
        retrying do
          client.lock(name, config[:ttl]) do |lock|
            lock ? yield : raise(LockError.new(name))
          end
        end
      end

      private

        def client
          Redlock::Client.new([url])
        end

        def url
          config[:url] || fail("No Redis URL specified")
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
