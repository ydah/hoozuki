# frozen_string_literal: true

module Hoozuki
  module Node
    class Choice
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def to_nfa(state)
        left_nfa = @children[0].to_nfa(state)
        right_nfa = @children[1].to_nfa(state)
        start_state = state.new_state
        accepts = left_nfa.accept | right_nfa.accept

        nfa = Automaton::NFA.new(start_state, accepts)
        nfa.merge_transitions(left_nfa)
        nfa.merge_transitions(right_nfa)
        nfa.add_epsilon_transition(start_state, left_nfa.start)
        nfa.add_epsilon_transition(start_state, right_nfa.start)
        nfa
      end
    end
  end
end
