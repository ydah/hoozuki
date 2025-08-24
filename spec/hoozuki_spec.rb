# frozen_string_literal: true

RSpec.describe Hoozuki do
  shared_examples 'regex matching behavior' do |mode|
    subject { described_class.new(pattern, engine: mode).match?(value) }

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
      include_examples 'regex matching behavior', :vm
    end

    context 'with :dfa mode' do
      include_examples 'regex matching behavior', :dfa
    end
  end
end
