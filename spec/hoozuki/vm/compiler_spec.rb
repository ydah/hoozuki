# frozen_string_literal: true

RSpec.describe Hoozuki::VM::Compiler do
  describe '#compile' do
    let(:compiler) { described_class.new }

    context 'with Literal node' do
      it 'compiles to Char and Match instructions' do
        node = Hoozuki::Node::Literal.new('a')
        compiler.compile(node)

        expect(compiler.instructions.size).to eq(2)
        expect(compiler.instructions[0]).to be_a(Hoozuki::Instruction::Char)
        expect(compiler.instructions[0].char).to eq('a')
        expect(compiler.instructions[1]).to be_a(Hoozuki::Instruction::Match)
      end

      it 'handles multibyte characters' do
        node = Hoozuki::Node::Literal.new('あ')
        compiler.compile(node)

        expect(compiler.instructions[0].char).to eq('あ')
      end
    end

    context 'with Epsilon node' do
      it 'compiles to only Match instruction' do
        node = Hoozuki::Node::Epsilon.new
        compiler.compile(node)

        expect(compiler.instructions.size).to eq(1)
        expect(compiler.instructions[0]).to be_a(Hoozuki::Instruction::Match)
      end
    end

    context 'with Concatenation node' do
      it 'compiles to sequential Char instructions' do
        node = Hoozuki::Node::Concatenation.new([
          Hoozuki::Node::Literal.new('a'),
          Hoozuki::Node::Literal.new('b')
        ])
        compiler.compile(node)

        expect(compiler.instructions.size).to eq(3)
        expect(compiler.instructions[0]).to be_a(Hoozuki::Instruction::Char)
        expect(compiler.instructions[0].char).to eq('a')
        expect(compiler.instructions[1]).to be_a(Hoozuki::Instruction::Char)
        expect(compiler.instructions[1].char).to eq('b')
        expect(compiler.instructions[2]).to be_a(Hoozuki::Instruction::Match)
      end

      it 'handles longer concatenations' do
        node = Hoozuki::Node::Concatenation.new([
          Hoozuki::Node::Literal.new('a'),
          Hoozuki::Node::Literal.new('b'),
          Hoozuki::Node::Literal.new('c')
        ])
        compiler.compile(node)

        expect(compiler.instructions.size).to eq(4)
        expect(compiler.instructions.map { |i| i.is_a?(Hoozuki::Instruction::Char) ? i.char : nil }.compact).to eq(['a', 'b', 'c'])
      end
    end

    context 'with Choice node' do
      it 'compiles with Split and Jmp instructions' do
        node = Hoozuki::Node::Choice.new([
          Hoozuki::Node::Literal.new('a'),
          Hoozuki::Node::Literal.new('b')
        ])
        compiler.compile(node)

        expect(compiler.instructions[0]).to be_a(Hoozuki::Instruction::Split)
        expect(compiler.instructions).to include(an_instance_of(Hoozuki::Instruction::Jmp))
        expect(compiler.instructions.last).to be_a(Hoozuki::Instruction::Match)
      end

      it 'sets correct Split targets' do
        node = Hoozuki::Node::Choice.new([
          Hoozuki::Node::Literal.new('a'),
          Hoozuki::Node::Literal.new('b')
        ])
        compiler.compile(node)

        split = compiler.instructions[0]
        expect(split.left).to eq(1)
        expect(split.right).to be > split.left
      end
    end

    context 'with Repetition node' do
      context 'with zero_or_more' do
        it 'compiles with Split and Jmp for looping' do
          node = Hoozuki::Node::Repetition.new(
            Hoozuki::Node::Literal.new('a'),
            :zero_or_more
          )
          compiler.compile(node)

          expect(compiler.instructions[0]).to be_a(Hoozuki::Instruction::Split)
          expect(compiler.instructions).to include(an_instance_of(Hoozuki::Instruction::Jmp))
          expect(compiler.instructions.last).to be_a(Hoozuki::Instruction::Match)
        end

        it 'creates correct loop structure' do
          node = Hoozuki::Node::Repetition.new(
            Hoozuki::Node::Literal.new('a'),
            :zero_or_more
          )
          compiler.compile(node)

          split = compiler.instructions[0]
          expect(split).to be_a(Hoozuki::Instruction::Split)
          jmp = compiler.instructions.find { |i| i.is_a?(Hoozuki::Instruction::Jmp) }
          expect(jmp.target).to eq(0)
        end
      end

      context 'with one_or_more' do
        it 'compiles with Char followed by Split' do
          node = Hoozuki::Node::Repetition.new(
            Hoozuki::Node::Literal.new('a'),
            :one_or_more
          )
          compiler.compile(node)

          expect(compiler.instructions[0]).to be_a(Hoozuki::Instruction::Char)
          expect(compiler.instructions[1]).to be_a(Hoozuki::Instruction::Split)
          expect(compiler.instructions.last).to be_a(Hoozuki::Instruction::Match)
        end

        it 'creates correct loop structure' do
          node = Hoozuki::Node::Repetition.new(
            Hoozuki::Node::Literal.new('a'),
            :one_or_more
          )
          compiler.compile(node)

          split = compiler.instructions[1]
          expect(split.left).to eq(0)
          expect(split.right).to eq(2)
        end
      end

      context 'with optional' do
        it 'compiles with Split around the node' do
          node = Hoozuki::Node::Repetition.new(
            Hoozuki::Node::Literal.new('a'),
            :optional
          )
          compiler.compile(node)

          expect(compiler.instructions[0]).to be_a(Hoozuki::Instruction::Split)
          expect(compiler.instructions[1]).to be_a(Hoozuki::Instruction::Char)
          expect(compiler.instructions.last).to be_a(Hoozuki::Instruction::Match)
        end

        it 'sets Split to allow skipping' do
          node = Hoozuki::Node::Repetition.new(
            Hoozuki::Node::Literal.new('a'),
            :optional
          )
          compiler.compile(node)

          split = compiler.instructions[0]
          expect(split.left).to eq(1)
          expect(split.right).to eq(2)
        end
      end
    end

    context 'with complex nested structures' do
      it 'compiles choice within concatenation' do
        node = Hoozuki::Node::Concatenation.new([
          Hoozuki::Node::Literal.new('x'),
          Hoozuki::Node::Choice.new([
            Hoozuki::Node::Literal.new('a'),
            Hoozuki::Node::Literal.new('b')
          ]),
          Hoozuki::Node::Literal.new('y')
        ])
        compiler.compile(node)

        expect(compiler.instructions).to include(an_instance_of(Hoozuki::Instruction::Split))
        expect(compiler.instructions.last).to be_a(Hoozuki::Instruction::Match)
      end

      it 'compiles repetition within choice' do
        node = Hoozuki::Node::Choice.new([
          Hoozuki::Node::Repetition.new(
            Hoozuki::Node::Literal.new('a'),
            :zero_or_more
          ),
          Hoozuki::Node::Literal.new('b')
        ])
        compiler.compile(node)

        expect(compiler.instructions).to include(an_instance_of(Hoozuki::Instruction::Split))
        expect(compiler.instructions).to include(an_instance_of(Hoozuki::Instruction::Jmp))
        expect(compiler.instructions.last).to be_a(Hoozuki::Instruction::Match)
      end
    end
  end

  describe '#instructions' do
    it 'returns empty array initially' do
      compiler = described_class.new
      expect(compiler.instructions).to eq([])
    end

    it 'accumulates instructions after compile' do
      compiler = described_class.new
      node = Hoozuki::Node::Literal.new('a')
      compiler.compile(node)

      expect(compiler.instructions).not_to be_empty
    end
  end
end
