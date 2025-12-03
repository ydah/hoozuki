# frozen_string_literal: true

RSpec.describe Hoozuki::Instruction do
  describe Hoozuki::Instruction::Char do
    describe '#initialize' do
      it 'sets the character' do
        instruction = described_class.new('a')
        expect(instruction.char).to eq('a')
      end

      it 'handles multibyte characters' do
        instruction = described_class.new('あ')
        expect(instruction.char).to eq('あ')
      end
    end

    describe '#char=' do
      it 'allows updating the character' do
        instruction = described_class.new('a')
        instruction.char = 'b'
        expect(instruction.char).to eq('b')
      end
    end
  end

  describe Hoozuki::Instruction::Jmp do
    describe '#initialize' do
      it 'sets the target' do
        instruction = described_class.new(5)
        expect(instruction.target).to eq(5)
      end

      it 'handles zero target' do
        instruction = described_class.new(0)
        expect(instruction.target).to eq(0)
      end
    end

    describe '#target=' do
      it 'allows updating the target' do
        instruction = described_class.new(5)
        instruction.target = 10
        expect(instruction.target).to eq(10)
      end
    end
  end

  describe Hoozuki::Instruction::Match do
    describe '#initialize' do
      it 'creates a Match instruction' do
        instruction = described_class.new
        expect(instruction).to be_a(described_class)
      end
    end
  end

  describe Hoozuki::Instruction::Split do
    describe '#initialize' do
      it 'sets left and right targets' do
        instruction = described_class.new(3, 7)
        expect(instruction.left).to eq(3)
        expect(instruction.right).to eq(7)
      end

      it 'handles zero targets' do
        instruction = described_class.new(0, 0)
        expect(instruction.left).to eq(0)
        expect(instruction.right).to eq(0)
      end
    end

    describe '#left=' do
      it 'allows updating the left target' do
        instruction = described_class.new(3, 7)
        instruction.left = 5
        expect(instruction.left).to eq(5)
      end
    end

    describe '#right=' do
      it 'allows updating the right target' do
        instruction = described_class.new(3, 7)
        instruction.right = 10
        expect(instruction.right).to eq(10)
      end
    end
  end
end
