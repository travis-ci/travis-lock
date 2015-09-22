# http://hashrocket.com/blog/posts/advisory-locks-in-postgres
# https://github.com/mceachen/with_advisory_lock
# 13.3.4. Advisory Locks : http://www.postgresql.org/docs/9.3/static/explicit-locking.html
# http://www.postgresql.org/docs/9.3/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS

require 'zlib'
require 'active_record'
require 'travis/lock/support/retry'

module Travis
  module Lock
    class Postgresql < Struct.new(:name, :options)
      def initialize(*)
        super
        fail 'lock name cannot be blank' if name.nil? || name.empty?
      end

      def exclusive(&block)
        with_timeout { obtain_lock }
        transactional? ? connection.transaction(&block) : with_release(&block)
      end

      private

        def with_timeout(&block)
          try? ? Retry.new(name, options).run(&block) : with_statement_timeout(&block)
        end

        def obtain_lock
          result = connection.select_value("select #{pg_function}(#{key});")
          try? ? result == 't' : true
        end

        def with_release
          yield
        ensure
          connection.execute("select pg_advisory_unlock(#{key});")
        end

        def try?
          !!options[:try]
        end

        def timeout
          options[:timeout] || 30
        end

        def transactional?
          !!options[:transactional]
        end

        def with_statement_timeout
          connection.execute("set statement_timeout to #{Integer(timeout * 1000)};")
          yield
        rescue ActiveRecord::StatementInvalid => e
          retry if defined?(PG) && e.original_exception.is_a?(PG::QueryCanceled)
          timeout!
        end

        def pg_function
          func = ['pg', 'advisory', 'lock']
          func.insert(2, 'xact') if transactional?
          func.insert(1, 'try')  if try?
          func.join('_')
        end

        def connection
          ActiveRecord::Base.connection
        end

        def key
          Zlib.crc32(name).to_i & 0x7fffffff
        end
    end
  end
end
