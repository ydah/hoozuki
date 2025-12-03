# frozen_string_literal: true

RSpec.describe Hoozuki::Parser do
  describe '#parse' do
    context 'with a single literal' do
      it 'returns a Literal node' do
        result = described_class.new.parse('a')
        expect(result).to be_a(Hoozuki::Node::Literal)
        expect(result.value).to eq('a')
      end
    end

    context 'with concatenation' do
      it 'returns a Concatenation node' do
        result = described_class.new.parse('abc')
        expect(result).to be_a(Hoozuki::Node::Concatenation)
        expect(result.children.length).to eq(3)
        expect(result.children.map(&:value)).to eq(%w[a b c])
      end

      it 'handles multibyte characters' do
        result = described_class.new.parse('あいう')
        expect(result).to be_a(Hoozuki::Node::Concatenation)
        expect(result.children.map(&:value)).to eq(%w[あ い う])
      end
    end

    context 'with alternation' do
      it 'returns a Choice node' do
        result = described_class.new.parse('a|b')
        expect(result).to be_a(Hoozuki::Node::Choice)
        expect(result.children.length).to eq(2)
      end

      it 'parses choice with concatenation' do
        result = described_class.new.parse('cat|dog')
        expect(result).to be_a(Hoozuki::Node::Choice)
        expect(result.children[0]).to be_a(Hoozuki::Node::Concatenation)
        expect(result.children[1]).to be_a(Hoozuki::Node::Concatenation)
      end

      it 'parses multiple choices' do
        result = described_class.new.parse('a|b|c')
        expect(result).to be_a(Hoozuki::Node::Choice)
        expect(result.children.length).to eq(3)
      end
    end

    context 'with zero or more quantifier' do
      it 'returns a Repetition node with zero_or_more' do
        result = described_class.new.parse('a*')
        expect(result).to be_a(Hoozuki::Node::Repetition)
        expect(result.zero_or_more?).to be true
      end
    end

    context 'with one or more quantifier' do
      it 'returns a Repetition node with one_or_more' do
        result = described_class.new.parse('a+')
        expect(result).to be_a(Hoozuki::Node::Repetition)
        expect(result.one_or_more?).to be true
      end
    end

    context 'with optional quantifier' do
      it 'returns a Repetition node with optional' do
        result = described_class.new.parse('a?')
        expect(result).to be_a(Hoozuki::Node::Repetition)
        expect(result.optional?).to be true
      end
    end

    context 'with grouping' do
      it 'returns correct structure' do
        result = described_class.new.parse('(ab)')
        expect(result).to be_a(Hoozuki::Node::Concatenation)
        expect(result.children.length).to eq(2)
      end

      it 'parses nested groups' do
        result = described_class.new.parse('((a))')
        expect(result).to be_a(Hoozuki::Node::Literal)
        expect(result.value).to eq('a')
      end

      it 'parses group with empty alternative' do
        result = described_class.new.parse('(a|)')
        expect(result).to be_a(Hoozuki::Node::Choice)
        expect(result.children.last).to be_a(Hoozuki::Node::Epsilon)
      end

      it 'parses group repetition' do
        result = described_class.new.parse('(ab)*')
        expect(result).to be_a(Hoozuki::Node::Repetition)
        expect(result.child).to be_a(Hoozuki::Node::Concatenation)
        expect(result.zero_or_more?).to be true
      end
    end

    context 'with escaped characters' do
      it 'treats escaped special characters as literals' do
        result = described_class.new.parse('\\*')
        expect(result).to be_a(Hoozuki::Node::Literal)
        expect(result.value).to eq('*')
      end

      it 'escapes opening parenthesis' do
        result = described_class.new.parse('\\(')
        expect(result).to be_a(Hoozuki::Node::Literal)
        expect(result.value).to eq('(')
      end

      it 'escapes closing parenthesis' do
        result = described_class.new.parse('\\)')
        expect(result).to be_a(Hoozuki::Node::Literal)
        expect(result.value).to eq(')')
      end

      it 'escapes pipe character' do
        result = described_class.new.parse('\\|')
        expect(result).to be_a(Hoozuki::Node::Literal)
        expect(result.value).to eq('|')
      end

      it 'escapes backslash' do
        result = described_class.new.parse('\\\\')
        expect(result).to be_a(Hoozuki::Node::Literal)
        expect(result.value).to eq('\\')
      end

      it 'raises error for incomplete escape' do
        expect { described_class.new.parse('\\') }.to raise_error
      end
    end

    context 'with error cases' do
      it 'raises error for unmatched opening parenthesis' do
        expect { described_class.new.parse('(abc') }.to raise_error
      end

      it 'raises error for unmatched closing parenthesis' do
        expect { described_class.new.parse('abc)') }.to raise_error
      end

      it 'raises error for nested unmatched parentheses' do
        expect { described_class.new.parse('((a)') }.to raise_error
      end
    end

    context 'with empty alternation' do
      it 'returns a Choice with Epsilon' do
        result = described_class.new.parse('a|')
        expect(result).to be_a(Hoozuki::Node::Choice)
        expect(result.children.length).to eq(2)
        expect(result.children.last).to be_a(Hoozuki::Node::Epsilon)
      end
    end

    context 'with complex pattern' do
      it 'parses correctly' do
        result = described_class.new.parse('a(b|c)*d')
        expect(result).to be_a(Hoozuki::Node::Concatenation)
        expect(result.children.length).to eq(3)
        expect(result.children[1]).to be_a(Hoozuki::Node::Repetition)
      end
    end
  end
end
