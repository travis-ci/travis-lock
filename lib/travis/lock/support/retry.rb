module Travis
  module Lock
    class Retry < Struct.new(:name, :options)
      WAIT = 0.0001..0.0009

      def run
        wait until result = yield
        result
      end

      def wait
        sleep(rand(options[:wait] || WAIT))
        timeout! if timeout?
      end

      def started
        @started ||= Time.now
      end

      def timeout?
        started + timeout < Time.now
      end

      def timeout
        options[:timeout] || 30
      end

      def timeout!
        fail Timeout.new(name, options)
      end
    end
  end
end
