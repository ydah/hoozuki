# frozen_string_literal: true

class Hoozuki
  module Node
    class Repetition
      attr_reader :child

      def initialize(child, quantifier)
        @child = child
        @quantifier = quantifier
      end

      def zero_or_more?
        @quantifier == :zero_or_more
      end

      def one_or_more?
        @quantifier == :one_or_more
      end

      def optional?
        @quantifier == :optional
      end
    end
  end
end
