# frozen_string_literal: true

RSpec.describe Hoozuki do
  describe '#match?' do
    subject { described_class.new(pattern).match?(value) }

    context 'with pattern "a|b*"' do
      let(:pattern) { 'a|b*' }

      context 'when text is "a"' do
        let(:value) { 'a' }
        it { is_expected.to be true }
      end

      context 'when text is "b"' do
        let(:value) { 'b' }
        it { is_expected.to be true }
      end

      context 'when text is "bb"' do
        let(:value) { 'bb' }
        it { is_expected.to be true }
      end

      context 'when text is "bbb"' do
        let(:value) { 'bbb' }
        it { is_expected.to be true }
      end

      context 'when text is "" (empty)' do
        let(:value) { '' }
        it { is_expected.to be true }
      end

      context 'when text is "c"' do
        let(:value) { 'c' }
        it { is_expected.to be false }
      end
    end

    context 'with pattern "ab(cd|)"' do
      let(:pattern) { 'ab(cd|)' }

      xit 'matches "abcd" and "ab"' do
        regex = described_class.new(pattern)
        expect(regex.match?('abcd')).to be true
        expect(regex.match?('ab')).to be true
      end

      xit 'does not match "abc"' do
        regex = described_class.new(pattern)
        expect(regex.match?('abc')).to be false
      end
    end

    context 'with pattern "a+b"' do
      let(:pattern) { 'a+b' }

      it 'matches "ab", "aab", "aaab"' do
        regex = described_class.new(pattern)
        expect(regex.match?('ab')).to be true
        expect(regex.match?('aab')).to be true
        expect(regex.match?('aaab')).to be true
      end

      xit 'does not match "a" or "b"' do
        regex = described_class.new(pattern)
        expect(regex.match?('a')).to be false
        expect(regex.match?('b')).to be false
      end
    end

    context 'with literal pattern "a|b*"' do
      let(:pattern) { 'a\\|b\\*' }

      it 'matches the literal string "a|b*"' do
        regex = described_class.new(pattern)
        expect(regex.match?('a|b*')).to be true
      end

      it 'does not match "ab"' do
        regex = described_class.new(pattern)
        expect(regex.match?('ab')).to be false
      end
    end

    context 'with multi-byte characters pattern "正規表現(太郎|次郎)"' do
      let(:pattern) { '正規表現(太郎|次郎)' }

      it 'matches "正規表現太郎" and "正規表現次郎"' do
        regex = described_class.new(pattern)
        expect(regex.match?('正規表現太郎')).to be true
        expect(regex.match?('正規表現次郎')).to be true
      end

      it 'does not match "正規表現三郎"' do
        regex = described_class.new(pattern)
        expect(regex.match?('正規表現三郎')).to be false
      end
    end
  end
end
