# frozen_string_literal: true

RSpec.describe Hoozuki::Automaton::DFA do
  describe '.from_nfa' do
    let(:state) { Hoozuki::Automaton::StateID.new(0) }

    it 'converts simple NFA to DFA' do
      node = Hoozuki::Node::Literal.new('a')
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa).to be_a(described_class)
      expect(dfa.start).to be_a(Integer)
      expect(dfa.accept).to be_a(Set)
      expect(dfa.transitions).not_to be_empty
    end

    it 'converts choice NFA to DFA' do
      node = Hoozuki::Node::Choice.new([
        Hoozuki::Node::Literal.new('a'),
        Hoozuki::Node::Literal.new('b')
      ])
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa.start).to be_a(Integer)
      expect(dfa.transitions.map { |_, label, _| label }).to include('a', 'b')
    end

    it 'converts concatenation NFA to DFA' do
      node = Hoozuki::Node::Concatenation.new([
        Hoozuki::Node::Literal.new('a'),
        Hoozuki::Node::Literal.new('b')
      ])
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa.start).to be_a(Integer)
      expect(dfa.accept).not_to be_empty
    end

    it 'handles alternation patterns' do
      node = Hoozuki::Parser.new.parse('a|b')
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa.transitions.size).to be >= 2
    end

    it 'handles repetition patterns' do
      node = Hoozuki::Parser.new.parse('a*')
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa.accept).to include(dfa.start)
    end
  end

  describe '#match?' do
    let(:state) { Hoozuki::Automaton::StateID.new(0) }

    it 'matches using DFA for single literal' do
      node = Hoozuki::Node::Literal.new('a')
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa.match?('a', false)).to be true
      expect(dfa.match?('b', false)).to be false
    end

    it 'matches choice pattern using DFA' do
      node = Hoozuki::Node::Choice.new([
        Hoozuki::Node::Literal.new('a'),
        Hoozuki::Node::Literal.new('b')
      ])
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa.match?('a', false)).to be true
      expect(dfa.match?('b', false)).to be true
      expect(dfa.match?('c', false)).to be false
    end

    it 'matches concatenation pattern using DFA' do
      node = Hoozuki::Node::Concatenation.new([
        Hoozuki::Node::Literal.new('a'),
        Hoozuki::Node::Literal.new('b')
      ])
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      expect(dfa.match?('ab', false)).to be true
      expect(dfa.match?('a', false)).to be false
      expect(dfa.match?('abc', false)).to be false
    end

    context 'with simple literal' do
      it 'matches exact string' do
        node = Hoozuki::Parser.new.parse('abc')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        dfa = described_class.from_nfa(nfa, false)

        expect(dfa.match?('abc', false)).to be true
      end

      it 'does not match different string' do
        node = Hoozuki::Parser.new.parse('abc')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        dfa = described_class.from_nfa(nfa, false)

        expect(dfa.match?('abd', false)).to be false
      end
    end

    context 'with alternation' do
      it 'matches either branch' do
        node = Hoozuki::Parser.new.parse('a|b')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        dfa = described_class.from_nfa(nfa, false)

        expect(dfa.match?('a', false)).to be true
        expect(dfa.match?('b', false)).to be true
        expect(dfa.match?('c', false)).to be false
      end
    end
  end

  describe '#next_transition' do
    let(:state) { Hoozuki::Automaton::StateID.new(0) }

    it 'finds correct next state' do
      node = Hoozuki::Parser.new.parse('a')
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      next_state = dfa.next_transition(dfa.start, 'a', false)
      expect(next_state).not_to be_nil
    end

    it 'returns nil for invalid transition' do
      node = Hoozuki::Parser.new.parse('a')
      nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa, false)

      next_state = dfa.next_transition(dfa.start, 'b', false)
      expect(next_state).to be_nil
    end
  end
end
