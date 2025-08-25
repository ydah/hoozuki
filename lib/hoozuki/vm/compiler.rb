# frozen_string_literal: true

class Hoozuki
  module VM
    class Compiler
      attr_reader :instructions

      def initialize
        @pc = 0
        @instructions = []
      end

      def compile(ast)
        _compile(ast)
        @pc += 1
        @instructions << Instruction::Match.new
      end

      private

      def _compile(ast)
        case ast
        when Hoozuki::Node::Literal
          emit(Hoozuki::Instruction::Char.new(ast.value))
        when Hoozuki::Node::Epsilon
          # Do nothing for epsilon
        when Node::Repetition
          if ast.zero_or_more?
            split = @pc
            emit(Hoozuki::Instruction::Split.new(@pc + 1, 0))
            _compile(ast.child)
            emit(Hoozuki::Instruction::Jmp.new(split))
            patch(split, Hoozuki::Instruction::Split.new(split + 1, @pc))
          elsif ast.one_or_more?
            start = @pc
            _compile(ast.child)
            emit(Hoozuki::Instruction::Split.new(start, @pc + 1))
          elsif ast.optional?
            split = @pc
            emit(Hoozuki::Instruction::Split.new(0, 0))
            start = @pc
            _compile(ast.child)
            last = @pc
            patch(split, Hoozuki::Instruction::Split.new(start, last))
          end
        when Node::Choice
          split = @pc
          @pc += 1
          @instructions << Hoozuki::Instruction::Split.new(@pc, 0)
          _compile(ast.children.first)
          jump = @pc
          emit(Hoozuki::Instruction::Jmp.new(0))

          unless @instructions[split].is_a?(Hoozuki::Instruction::Split)
            raise "Instruction at pc #{split} is not a Split"
          end

          @instructions[split].right = @pc

          _compile(ast.children.last)

          raise "Instruction at pc #{jump} is not a Jmp" unless @instructions[jump].is_a?(Hoozuki::Instruction::Jmp)

          @instructions[jump].target = @pc

        when Node::Concatenation
          ast.children.each do |child|
            _compile(child)
          end
        end
      end

      def emit(instruction)
        @instructions << instruction
        @pc += 1
      end

      def patch(pc, instruction)
        @instructions[pc] = instruction
      end
    end
  end
end
