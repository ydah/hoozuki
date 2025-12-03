# frozen_string_literal: true

module Hoozuki
  module Node
    class Literal
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def to_nfa(state)
        start_state = state.new_state
        accept_state = state.new_state
        nfa = Automaton::NFA.new(start_state, [accept_state])
        nfa.add_transition(start_state, @value, accept_state)
        nfa
      end
    end
  end
end
