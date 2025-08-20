# frozen_string_literal: true

class Hoozuki
  module Node
    class Choice
      attr_reader :children

      def initialize(children)
        @children = children
      end
    end
  end
end
