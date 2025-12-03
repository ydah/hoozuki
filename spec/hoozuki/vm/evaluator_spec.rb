# frozen_string_literal: true

RSpec.describe Hoozuki::VM::Evaluator do
  describe '.evaluate' do
    context 'with single Char instruction' do
      it 'matches exact character' do
        instructions = [
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'a')).to be true
      end

      it 'does not match different character' do
        instructions = [
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'b')).to be false
      end

      it 'does not match empty string' do
        instructions = [
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, '')).to be false
      end

      it 'handles multibyte characters' do
        instructions = [
          Hoozuki::Instruction::Char.new('あ'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'あ')).to be true
        expect(described_class.evaluate(instructions, 'い')).to be false
      end
    end

    context 'with multiple Char instructions' do
      it 'matches sequential characters' do
        instructions = [
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Char.new('b'),
          Hoozuki::Instruction::Char.new('c'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'abc')).to be true
      end

      it 'does not match partial sequence' do
        instructions = [
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Char.new('b'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'a')).to be false
        expect(described_class.evaluate(instructions, 'abc')).to be false
      end
    end

    context 'with Jmp instruction' do
      it 'jumps to target address' do
        instructions = [
          Hoozuki::Instruction::Jmp.new(2),
          Hoozuki::Instruction::Char.new('x'),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'a')).to be true
        expect(described_class.evaluate(instructions, 'x')).to be false
      end

      it 'handles backward jumps for loops' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 3),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Jmp.new(0),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, '')).to be true
        expect(described_class.evaluate(instructions, 'a')).to be true
        expect(described_class.evaluate(instructions, 'aaa')).to be true
      end
    end

    context 'with Split instruction' do
      it 'tries left branch first' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 3),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new,
          Hoozuki::Instruction::Char.new('b'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'a')).to be true
      end

      it 'tries right branch if left fails' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 3),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new,
          Hoozuki::Instruction::Char.new('b'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'b')).to be true
      end

      it 'returns false if both branches fail' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 3),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new,
          Hoozuki::Instruction::Char.new('b'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'c')).to be false
      end
    end

    context 'with Match instruction' do
      it 'returns true only if entire input is consumed' do
        instructions = [
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, '')).to be true
        expect(described_class.evaluate(instructions, 'a')).to be false
      end

      it 'returns false if input remains unconsumed' do
        instructions = [
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'ab')).to be false
      end
    end

    context 'with complex patterns' do
      it 'handles choice pattern (a|b)' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 3),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Jmp.new(4),
          Hoozuki::Instruction::Char.new('b'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'a')).to be true
        expect(described_class.evaluate(instructions, 'b')).to be true
        expect(described_class.evaluate(instructions, 'c')).to be false
      end

      it 'handles zero-or-more pattern (a*)' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 3),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Jmp.new(0),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, '')).to be true
        expect(described_class.evaluate(instructions, 'a')).to be true
        expect(described_class.evaluate(instructions, 'aa')).to be true
        expect(described_class.evaluate(instructions, 'aaa')).to be true
        expect(described_class.evaluate(instructions, 'b')).to be false
      end

      it 'handles one-or-more pattern (a+)' do
        instructions = [
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Split.new(0, 2),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'a')).to be true
        expect(described_class.evaluate(instructions, 'aa')).to be true
        expect(described_class.evaluate(instructions, 'aaa')).to be true
        expect(described_class.evaluate(instructions, '')).to be false
      end

      it 'handles optional pattern (a?)' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 2),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, '')).to be true
        expect(described_class.evaluate(instructions, 'a')).to be true
        expect(described_class.evaluate(instructions, 'aa')).to be false
      end
    end

    context 'with edge cases' do
      it 'handles empty instruction list' do
        instructions = []

        expect(described_class.evaluate(instructions, '')).to be false
        expect(described_class.evaluate(instructions, 'a')).to be false
      end

      it 'handles invalid pc (out of bounds)' do
        instructions = [
          Hoozuki::Instruction::Jmp.new(10),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, '')).to be false
      end

      it 'handles long input strings' do
        instructions = [
          Hoozuki::Instruction::Split.new(1, 3),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Jmp.new(0),
          Hoozuki::Instruction::Match.new
        ]

        long_input = 'a' * 1000
        expect(described_class.evaluate(instructions, long_input)).to be true
      end
    end

    context 'with initial positions' do
      it 'can start from non-zero input position' do
        instructions = [
          Hoozuki::Instruction::Char.new('b'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'ab', 1, 0)).to be true
      end

      it 'can start from non-zero pc' do
        instructions = [
          Hoozuki::Instruction::Char.new('x'),
          Hoozuki::Instruction::Char.new('a'),
          Hoozuki::Instruction::Match.new
        ]

        expect(described_class.evaluate(instructions, 'a', 0, 1)).to be true
      end
    end
  end
end
