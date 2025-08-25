# frozen_string_literal: true

class Hoozuki
  module VM
    class Evaluator
      class << self
        def evaluate(instructions, input, input_pos = 0, pc = 0)
          new._evaluate(instructions, input, input_pos, pc)
        end
      end

      def _evaluate(instructions, input, input_pos, pc)
        loop do
          return false if pc >= instructions.size

          inst = instructions[pc]
          case inst
          when Hoozuki::Instruction::Char
            return false if input_pos >= input.size || input[input_pos] != inst.char

            input_pos += 1
            pc += 1
          when Hoozuki::Instruction::Jmp
            pc = inst.target
          when Hoozuki::Instruction::Split
            return true if _evaluate(instructions, input, input_pos, inst.left)

            pc = inst.right

          when Hoozuki::Instruction::Match
            return input_pos == input.length
          else
            raise "Unknown instruction: #{inst.class}"
          end
        end
      end
    end
  end
end
