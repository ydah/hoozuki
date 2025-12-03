# frozen_string_literal: true

module Hoozuki
  module Node
    class Choice
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def to_nfa(state)
        child_nfas = @children.map { |child| child.to_nfa(state) }
        start_state = state.new_state
        accepts = child_nfas.flat_map(&:accept).to_set
        nfa = Automaton::NFA.new(start_state, accepts)
        child_nfas.each do |child_nfa|
          nfa.merge_transitions(child_nfa)
          nfa.add_epsilon_transition(start_state, child_nfa.start)
        end
        nfa
      end
    end
  end
end
