# frozen_string_literal: true

RSpec.describe Hoozuki::Automaton::DFA::Builder do
  describe '#call' do
    let(:state) { Hoozuki::Automaton::StateID.new(0) }

    context 'with simple NFA' do
      it 'builds a DFA' do
        node = Hoozuki::Node::Literal.new('a')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        builder = described_class.new(nfa, false)
        dfa = builder.call

        expect(dfa).to be_a(Hoozuki::Automaton::DFA)
        expect(dfa.start).to be_a(Integer)
        expect(dfa.accept).to be_a(Set)
        expect(dfa.transitions).to be_a(Set)
      end
    end

    context 'with NFA containing epsilon transitions' do
      it 'eliminates epsilon transitions' do
        node = Hoozuki::Parser.new.parse('a?')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        builder = described_class.new(nfa, false)
        dfa = builder.call

        epsilon_transitions = dfa.transitions.select { |_, label, _| label.nil? }
        expect(epsilon_transitions).to be_empty
      end
    end


    context 'with alternation' do
      it 'creates correct number of states' do
        node = Hoozuki::Parser.new.parse('a|b')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        builder = described_class.new(nfa, false)
        dfa = builder.call

        expect(dfa.transitions.size).to be >= 2
      end
    end

    context 'with repetition' do
      it 'handles loops correctly' do
        node = Hoozuki::Parser.new.parse('a*')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        builder = described_class.new(nfa, false)
        dfa = builder.call

        expect(dfa.accept).to include(dfa.start)
      end
    end

    context 'with concatenation' do
      it 'builds sequential transitions' do
        node = Hoozuki::Parser.new.parse('abc')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        builder = described_class.new(nfa, false)
        dfa = builder.call

        expect(dfa.transitions.size).to be >= 3
      end
    end

    context 'with complex pattern' do
      it 'builds correct DFA structure' do
        node = Hoozuki::Parser.new.parse('(a|b)*c')
        nfa = Hoozuki::Automaton::NFA.new_from_node(node, state)
        builder = described_class.new(nfa, false)
        dfa = builder.call

        expect(dfa).to be_a(Hoozuki::Automaton::DFA)
        expect(dfa.accept).not_to be_empty
      end
    end
  end
end
