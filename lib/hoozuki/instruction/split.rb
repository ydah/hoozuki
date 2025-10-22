# frozen_string_literal: true

module Hoozuki
  module Instruction
    class Split
      attr_accessor :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end
  end
end
