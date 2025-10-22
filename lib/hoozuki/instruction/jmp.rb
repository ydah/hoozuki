# frozen_string_literal: true

module Hoozuki
  module Instruction
    class Jmp
      attr_accessor :target

      def initialize(target)
        @target = target
      end
    end
  end
end
