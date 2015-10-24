require 'travis/lock/none'
require 'travis/lock/postgresql'
require 'travis/lock/redis'

module Travis
  module Lock
    class Timeout < StandardError
      def initialize(name, options)
        super("Could not obtain lock for #{name}: #{options.map { |pair| pair.join('=') }.join(' ')}")
      end
    end

    extend self

    attr_reader :default_strategy

    def exclusive(name, options = {}, &block)
      options[:strategy] ||= Lock.default_strategy || :none
      const_get(camelize(options[:strategy])).new(name, options).exclusive(&block)
    end

    private

      def camelize(object)
        object.to_s.split('_').collect(&:capitalize).join
      end
  end
end
