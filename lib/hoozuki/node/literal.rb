# frozen_string_literal: true

class Hoozuki
  module Node
    class Literal
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end
  end
end
