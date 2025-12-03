# frozen_string_literal: true

module Hoozuki
  module VM
    class Compiler
      attr_reader :instructions

      def initialize
        @pc = 0
        @instructions = []
      end

      def compile(ast)
        compile_node(ast)
        emit_match
      end

      private

      def compile_node(ast)
        case ast
        when Hoozuki::Node::Literal
          compile_literal(ast)
        when Hoozuki::Node::Epsilon
          # Do nothing for epsilon
        when Node::Repetition
          compile_repetition(ast)
        when Node::Choice
          compile_choice(ast)
        when Node::Concatenation
          compile_concatenation(ast)
        end
      end

      def compile_literal(node)
        emit(Hoozuki::Instruction::Char.new(node.value))
      end

      def compile_repetition(node)
        if node.zero_or_more?
          compile_zero_or_more(node.child)
        elsif node.one_or_more?
          compile_one_or_more(node.child)
        elsif node.optional?
          compile_optional(node.child)
        end
      end

      def compile_zero_or_more(child)
        split = @pc
        emit(Hoozuki::Instruction::Split.new(@pc + 1, 0))
        compile_node(child)
        emit(Hoozuki::Instruction::Jmp.new(split))
        patch(split, Hoozuki::Instruction::Split.new(split + 1, @pc))
      end

      def compile_one_or_more(child)
        start = @pc
        compile_node(child)
        emit(Hoozuki::Instruction::Split.new(start, @pc + 1))
      end

      def compile_optional(child)
        split = @pc
        emit(Hoozuki::Instruction::Split.new(0, 0))
        start = @pc
        compile_node(child)
        last = @pc
        patch(split, Hoozuki::Instruction::Split.new(start, last))
      end

      def compile_choice(node)
        split = @pc
        @pc += 1
        @instructions << Hoozuki::Instruction::Split.new(@pc, 0)
        compile_node(node.children.first)
        jump = @pc
        emit(Hoozuki::Instruction::Jmp.new(0))

        validate_split_instruction(split)
        @instructions[split].right = @pc

        compile_node(node.children.last)

        validate_jmp_instruction(jump)
        @instructions[jump].target = @pc
      end

      def compile_concatenation(node)
        node.children.each do |child|
          compile_node(child)
        end
      end

      def emit_match
        @pc += 1
        @instructions << Instruction::Match.new
      end

      def validate_split_instruction(pc)
        return if @instructions[pc].is_a?(Hoozuki::Instruction::Split)

        raise "Instruction at pc #{pc} is not a Split"
      end

      def validate_jmp_instruction(pc)
        return if @instructions[pc].is_a?(Hoozuki::Instruction::Jmp)

        raise "Instruction at pc #{pc} is not a Jmp"
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
