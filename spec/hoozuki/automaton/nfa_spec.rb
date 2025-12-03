# frozen_string_literal: true

RSpec.describe Hoozuki::Automaton::NFA do
  describe '.from_node' do
    let(:state) { Hoozuki::Automaton::StateID.new(0) }

    context 'with nil node' do
      it 'raises ArgumentError' do
        expect { described_class.from_node(nil, state) }.to raise_error(ArgumentError, 'Node cannot be nil')
      end
    end

    context 'with Literal node' do
      it 'creates NFA from literal node' do
        node = Hoozuki::Node::Literal.new('a')
        nfa = described_class.from_node(node, state)

        expect(nfa).to be_a(described_class)
        expect(nfa.start).to be_a(Hoozuki::Automaton::StateID)
        expect(nfa.accept).to be_an(Array)
        expect(nfa.accept.length).to eq(1)
        expect(nfa.transitions.size).to eq(1)
      end
    end

    context 'with Epsilon node' do
      it 'creates NFA from epsilon node' do
        node = Hoozuki::Node::Epsilon.new
        nfa = described_class.from_node(node, state)

        expect(nfa).to be_a(described_class)
        expect(nfa.accept.length).to eq(1)
        expect(nfa.transitions.size).to eq(1)
        expect(nfa.transitions.first[1]).to be_nil
      end
    end

    context 'with Concatenation node' do
      it 'creates NFA from concatenation node' do
        node = Hoozuki::Node::Concatenation.new([
          Hoozuki::Node::Literal.new('a'),
          Hoozuki::Node::Literal.new('b')
        ])
        nfa = described_class.from_node(node, state)

        expect(nfa).to be_a(described_class)
        expect(nfa.accept.length).to eq(1)
      end
    end

    context 'with Choice node' do
      it 'creates NFA from choice node' do
        node = Hoozuki::Node::Choice.new([
          Hoozuki::Node::Literal.new('a'),
          Hoozuki::Node::Literal.new('b')
        ])
        nfa = described_class.from_node(node, state)

        expect(nfa).to be_a(described_class)
        expect(nfa.accept.length).to eq(2)
      end
    end

    context 'with Repetition node' do
      it 'creates NFA from zero-or-more repetition' do
        node = Hoozuki::Node::Repetition.new(
          Hoozuki::Node::Literal.new('a'),
          :zero_or_more
        )
        nfa = described_class.from_node(node, state)

        expect(nfa).to be_a(described_class)
        expect(nfa.accept.length).to eq(2)
      end

      it 'creates NFA from one-or-more repetition' do
        node = Hoozuki::Node::Repetition.new(
          Hoozuki::Node::Literal.new('a'),
          :one_or_more
        )
        nfa = described_class.from_node(node, state)

        expect(nfa).to be_a(described_class)
        expect(nfa.accept.length).to eq(1)
      end

      it 'creates NFA from optional repetition' do
        node = Hoozuki::Node::Repetition.new(
          Hoozuki::Node::Literal.new('a'),
          :optional
        )
        nfa = described_class.from_node(node, state)

        expect(nfa).to be_a(described_class)
        expect(nfa.accept.length).to eq(2)
      end
    end

    context 'with complex node' do
      it 'delegates to node.to_nfa' do
        node = Hoozuki::Node::Literal.new('x')
        expect(node).to receive(:to_nfa).with(state).and_call_original

        described_class.from_node(node, state)
      end
    end
  end

  describe '#epsilon_closure' do
    it 'returns set containing start state with no epsilon transitions' do
      nfa = described_class.new(0, [1])
      nfa.add_transition(0, 'a', 1)

      closure = nfa.epsilon_closure(Set.new([0]))
      expect(closure).to include(0)
    end

    it 'follows epsilon transitions' do
      nfa = described_class.new(0, [2])
      nfa.add_epsilon_transition(0, 1)
      nfa.add_epsilon_transition(1, 2)

      closure = nfa.epsilon_closure(Set.new([0]))
      expect(closure).to include(0, 1, 2)
    end

    it 'handles multiple starting states' do
      nfa = described_class.new(0, [2])
      nfa.add_epsilon_transition(0, 1)
      nfa.add_epsilon_transition(2, 3)

      closure = nfa.epsilon_closure(Set.new([0, 2]))
      expect(closure).to include(0, 1, 2, 3)
    end
  end

  describe '#add_transition' do
    it 'adds a labeled transition' do
      nfa = described_class.new(0, [1])
      nfa.add_transition(0, 'a', 1)

      expect(nfa.transitions).to include([0, 'a', 1])
    end
  end

  describe '#add_epsilon_transition' do
    it 'adds an epsilon transition' do
      nfa = described_class.new(0, [1])
      nfa.add_epsilon_transition(0, 1)

      expect(nfa.transitions).to include([0, nil, 1])
    end
  end

  describe '#merge_transitions' do
    it 'merges transitions from another NFA' do
      nfa1 = described_class.new(0, [1])
      nfa1.add_transition(0, 'a', 1)

      nfa2 = described_class.new(2, [3])
      nfa2.add_transition(2, 'b', 3)

      nfa1.merge_transitions(nfa2)

      expect(nfa1.transitions).to include([0, 'a', 1], [2, 'b', 3])
    end
  end
end
