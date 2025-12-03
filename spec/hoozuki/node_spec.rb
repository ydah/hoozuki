# frozen_string_literal: true

RSpec.describe 'Hoozuki::Node' do
  let(:state) { Hoozuki::Automaton::StateID.new(0) }

  describe Hoozuki::Node::Literal do
    describe '#to_nfa' do
      it 'creates an NFA with a single transition' do
        node = described_class.new('a')
        nfa = node.to_nfa(state)

        expect(nfa).to be_a(Hoozuki::Automaton::NFA)
        expect(nfa.start).to be_a(Hoozuki::Automaton::StateID)
        expect(nfa.accept).to be_an(Array)
        expect(nfa.accept.length).to eq(1)
        expect(nfa.transitions.size).to eq(1)
      end

      it 'creates correct transition' do
        node = described_class.new('b')
        nfa = node.to_nfa(state)

        transition = nfa.transitions.first
        expect(transition[1]).to eq('b')
      end
    end
  end

  describe Hoozuki::Node::Epsilon do
    describe '#to_nfa' do
      it 'creates an NFA with epsilon transition' do
        node = described_class.new
        nfa = node.to_nfa(state)

        expect(nfa).to be_a(Hoozuki::Automaton::NFA)
        expect(nfa.transitions.size).to eq(1)
        transition = nfa.transitions.first
        expect(transition[1]).to be_nil
      end
    end
  end

  describe Hoozuki::Node::Repetition do
    describe '#to_nfa' do
      context 'with zero_or_more' do
        it 'creates correct NFA structure' do
          child = Hoozuki::Node::Literal.new('a')
          node = described_class.new(child, :zero_or_more)
          nfa = node.to_nfa(state)

          expect(nfa).to be_a(Hoozuki::Automaton::NFA)
          expect(nfa.accept.length).to eq(2)
        end
      end

      context 'with one_or_more' do
        it 'creates correct NFA structure' do
          child = Hoozuki::Node::Literal.new('a')
          node = described_class.new(child, :one_or_more)
          nfa = node.to_nfa(state)

          expect(nfa).to be_a(Hoozuki::Automaton::NFA)
          expect(nfa.accept.length).to eq(1)
        end
      end

      context 'with optional' do
        it 'creates correct NFA structure' do
          child = Hoozuki::Node::Literal.new('a')
          node = described_class.new(child, :optional)
          nfa = node.to_nfa(state)

          expect(nfa).to be_a(Hoozuki::Automaton::NFA)
          expect(nfa.accept.length).to eq(2)
        end
      end
    end
  end

  describe Hoozuki::Node::Choice do
    describe '#to_nfa' do
      it 'creates NFA with branches' do
        left = Hoozuki::Node::Literal.new('a')
        right = Hoozuki::Node::Literal.new('b')
        node = described_class.new([left, right])
        nfa = node.to_nfa(state)

        expect(nfa).to be_a(Hoozuki::Automaton::NFA)
        expect(nfa.accept.length).to eq(2)
      end
    end
  end

  describe Hoozuki::Node::Concatenation do
    describe '#to_nfa' do
      it 'creates NFA with sequential states' do
        children = [
          Hoozuki::Node::Literal.new('a'),
          Hoozuki::Node::Literal.new('b'),
          Hoozuki::Node::Literal.new('c')
        ]
        node = described_class.new(children)
        nfa = node.to_nfa(state)

        expect(nfa).to be_a(Hoozuki::Automaton::NFA)
        expect(nfa.accept.length).to eq(1)
      end
    end
  end
end
