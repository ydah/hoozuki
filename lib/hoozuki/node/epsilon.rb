# frozen_string_literal: true

module Hoozuki
  module Node
    class Epsilon
      def to_nfa(state)
        start_state = state.new_state
        accept_state = state.new_state
        nfa = Automaton::NFA.new(start_state, [accept_state])
        nfa.add_epsilon_transition(start_state, accept_state)
        nfa
      end
    end
  end
end
