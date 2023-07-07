# frozen_string_literal: true

module Travis
  module Lock
    class None < Struct.new(:name, :options)
      def exclusive
        yield
      end
    end
  end
end
