# frozen_string_literal: true

RSpec.describe Hoozuki do
  shared_examples 'regex matching behavior' do |mode|
    subject { described_class.match?(pattern, value, engine: mode) }

    context 'with basic concatenation' do
      let(:pattern) { 'abc' }

      context 'when text is "abc"' do
        let(:value) { 'abc' }

        it { is_expected.to be true }
      end

      context 'when text is "ab"' do
        let(:value) { 'ab' }

        it { is_expected.to be false }
      end

      context 'when text is "abcd"' do
        let(:value) { 'abcd' }

        it { is_expected.to be false }
      end
    end

    context 'with alternation "|"' do
      let(:pattern) { 'a|b' }

      context 'when text is "a"' do
        let(:value) { 'a' }

        it { is_expected.to be true }
      end

      context 'when text is "b"' do
        let(:value) { 'b' }

        it { is_expected.to be true }
      end

      context 'when text is "ab"' do
        let(:value) { 'ab' }

        it { is_expected.to be false }
      end
    end

    context 'with quantifiers "*", "+", "?"' do
      context 'with pattern "b*"' do
        let(:pattern) { 'b*' }

        context 'when text is "" (empty)' do
          let(:value) { '' }

          it { is_expected.to be true }
        end

        context 'when text is "b"' do
          let(:value) { 'b' }

          it { is_expected.to be true }
        end

        context 'when text is "bbb"' do
          let(:value) { 'bbb' }

          it { is_expected.to be true }
        end

        context 'when text is "c"' do
          let(:value) { 'c' }

          it { is_expected.to be false }
        end
      end

      context 'with pattern "a+"' do
        let(:pattern) { 'a+' }

        context 'when text is "a"' do
          let(:value) { 'a' }

          it { is_expected.to be true }
        end

        context 'when text is "aaa"' do
          let(:value) { 'aaa' }

          it { is_expected.to be true }
        end

        context 'when text is "" (empty)' do
          let(:value) { '' }

          it { is_expected.to be false }
        end
      end

      context 'with pattern "c?"' do
        let(:pattern) { 'c?' }

        context 'when text is "" (empty)' do
          let(:value) { '' }

          it { is_expected.to be true }
        end

        context 'when text is "c"' do
          let(:value) { 'c' }

          it { is_expected.to be true }
        end

        context 'when text is "cc"' do
          let(:value) { 'cc' }

          it { is_expected.to be false }
        end
      end
    end

    context 'with grouping "()"' do
      let(:pattern) { 'ab(cd|)' }

      context 'when text is "abcd"' do
        let(:value) { 'abcd' }

        it { is_expected.to be true }
      end

      context 'when text is "ab"' do
        let(:value) { 'ab' }

        it { is_expected.to be true }
      end

      context 'when text is "abc"' do
        let(:value) { 'abc' }

        it { is_expected.to be false }
      end
    end

    context 'with escape sequences "\\"' do
      context 'with pattern "a\\|b\\*"' do
        let(:pattern) { 'a\\|b\\*' }

        context 'when text is "a|b*"' do
          let(:value) { 'a|b*' }

          it { is_expected.to be true }
        end

        context 'when text is "ab"' do
          let(:value) { 'ab' }

          it { is_expected.to be false }
        end
      end

      context 'with pattern "\\(a\\+\\)"' do
        let(:pattern) { '\\(a\\+\\)' }

        context 'when text is "(a+)"' do
          let(:value) { '(a+)' }

          it { is_expected.to be true }
        end

        context 'when text is "a"' do
          let(:value) { 'a' }

          it { is_expected.to be false }
        end
      end
    end

    context 'with a combination of features' do
      let(:pattern) { 'a|b*c(de)?' }

      context 'when text is "a"' do
        let(:value) { 'a' }

        it { is_expected.to be true }
      end

      context 'when text is "bc"' do
        let(:value) { 'bc' }

        it { is_expected.to be true }
      end

      context 'when text is "cde"' do
        let(:value) { 'cde' }

        it { is_expected.to be true }
      end

      context 'when text is "bbbcde"' do
        let(:value) { 'bbbcde' }

        it { is_expected.to be true }
      end

      context 'when text is "bd"' do
        let(:value) { 'bd' }

        it { is_expected.to be false }
      end
    end

    context 'with multi-byte characters' do
      let(:pattern) { '(こん|おつ)*やっぴー' }

      context 'when text is "こんやっぴー"' do
        let(:value) { 'こんやっぴー' }

        it { is_expected.to be true }
      end

      context 'when text is "おつやっぴー"' do
        let(:value) { 'おつやっぴー' }

        it { is_expected.to be true }
      end

      context 'when text is "こんおつやっぴー"' do
        let(:value) { 'こんおつやっぴー' }

        it { is_expected.to be true }
      end

      context 'when text is "こんこんきーつね"' do
        let(:value) { 'こんこんきーつね' }

        it { is_expected.to be false }
      end
    end
  end

  describe '#match?' do
    context 'with :vm mode' do
      it_behaves_like 'regex matching behavior', :vm

      context 'with VM-specific edge cases' do
        it 'handles deeply nested structures' do
          pattern = '((((a))))'
          expect(described_class.match?(pattern, 'a', engine: :vm)).to be true
          expect(described_class.match?(pattern, 'b', engine: :vm)).to be false
        end

        it 'handles multiple quantifiers in sequence' do
          pattern = 'a*b+c?'
          expect(described_class.match?(pattern, 'bc', engine: :vm)).to be true
          expect(described_class.match?(pattern, 'abc', engine: :vm)).to be true
          expect(described_class.match?(pattern, 'aaabbbbc', engine: :vm)).to be true
          expect(described_class.match?(pattern, 'c', engine: :vm)).to be false
        end

        it 'handles empty alternations' do
          pattern = 'a|'
          expect(described_class.match?(pattern, 'a', engine: :vm)).to be true
          expect(described_class.match?(pattern, '', engine: :vm)).to be true
        end

        it 'handles nested groups with quantifiers' do
          pattern = '(ab)*'
          expect(described_class.match?(pattern, '', engine: :vm)).to be true
          expect(described_class.match?(pattern, 'ab', engine: :vm)).to be true
          expect(described_class.match?(pattern, 'abab', engine: :vm)).to be true
        end
      end
    end

    context 'with :dfa mode' do
      it_behaves_like 'regex matching behavior', :dfa

      context 'with DFA-specific edge cases' do
        it 'handles deeply nested structures' do
          pattern = '((((a))))'
          expect(described_class.match?(pattern, 'a', engine: :dfa)).to be true
          expect(described_class.match?(pattern, 'b', engine: :dfa)).to be false
        end

        it 'handles multiple quantifiers in sequence' do
          pattern = 'a*b+c?'
          expect(described_class.match?(pattern, 'bc', engine: :dfa)).to be true
          expect(described_class.match?(pattern, 'abc', engine: :dfa)).to be true
          expect(described_class.match?(pattern, 'aaabbbbc', engine: :dfa)).to be true
          expect(described_class.match?(pattern, 'c', engine: :dfa)).to be false
        end

        it 'handles empty alternations' do
          pattern = 'a|'
          expect(described_class.match?(pattern, 'a', engine: :dfa)).to be true
          expect(described_class.match?(pattern, '', engine: :dfa)).to be true
        end

        it 'handles nested groups with quantifiers' do
          pattern = '(ab)*'
          expect(described_class.match?(pattern, '', engine: :dfa)).to be true
          expect(described_class.match?(pattern, 'ab', engine: :dfa)).to be true
          expect(described_class.match?(pattern, 'abab', engine: :dfa)).to be true
        end
      end
    end

    context 'with common edge cases' do
      it 'handles single character patterns for both engines' do
        [:vm, :dfa].each do |engine|
          expect(described_class.match?('x', 'x', engine: engine)).to be true
          expect(described_class.match?('x', 'y', engine: engine)).to be false
        end
      end

      it 'handles very long patterns for both engines' do
        pattern = 'a' * 100
        input = 'a' * 100

        [:vm, :dfa].each do |engine|
          expect(described_class.match?(pattern, input, engine: engine)).to be true
        end
      end

      it 'handles patterns with all quantifier types for both engines' do
        pattern = 'a*b+c?d'

        [:vm, :dfa].each do |engine|
          expect(described_class.match?(pattern, 'bd', engine: engine)).to be true
          expect(described_class.match?(pattern, 'bcd', engine: engine)).to be true
          expect(described_class.match?(pattern, 'abcd', engine: engine)).to be true
          expect(described_class.match?(pattern, 'aaabbbbcd', engine: engine)).to be true
        end
      end
    end
  end

  describe '#compile' do
    context 'with :vm engine' do
      it 'returns instruction array' do
        result = described_class.compile('a', engine: :vm)
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Hoozuki::Instruction::Char).or(be_a(Hoozuki::Instruction::Match)))
      end

      it 'raises error for unknown engine' do
        expect { described_class.compile('a', engine: :unknown) }.to raise_error(ArgumentError, 'Unknown engine: unknown')
      end
    end

    context 'with :dfa engine' do
      it 'returns DFA object' do
        result = described_class.compile('a', engine: :dfa)
        expect(result).to be_a(Hoozuki::Automaton::DFA)
      end
    end
  end
end
