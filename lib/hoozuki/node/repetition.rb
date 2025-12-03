# frozen_string_literal: true

module Hoozuki
  module Node
    class Repetition
      attr_reader :child

      def initialize(child, quantifier)
        @child = child
        @quantifier = quantifier
      end

      def zero_or_more?
        @quantifier == :zero_or_more
      end

      def one_or_more?
        @quantifier == :one_or_more
      end

      def optional?
        @quantifier == :optional
      end

      def to_nfa(state)
        if zero_or_more?
          to_nfa_zero_or_more(state)
        elsif one_or_more?
          to_nfa_one_or_more(state)
        elsif optional?
          to_nfa_optional(state)
        end
      end

      private

      def to_nfa_zero_or_more(state)
        remain = @child.to_nfa(state)
        start_state = state.new_state
        accepts = remain.accept.dup << start_state

        nfa = Automaton::NFA.new(start_state, accepts)
        nfa.merge_transitions(remain)
        nfa.add_epsilon_transition(start_state, remain.start)

        remain.accept.each do |accept_state|
          nfa.add_epsilon_transition(accept_state, remain.start)
        end

        nfa
      end

      def to_nfa_one_or_more(state)
        remain = @child.to_nfa(state)
        start_state = state.new_state
        accept_state = state.new_state
        nfa = Automaton::NFA.new(start_state, [accept_state])

        nfa.transitions.merge(remain.transitions)
        nfa.add_epsilon_transition(start_state, remain.start)
        remain.accept.each do |remain_accept|
          nfa.add_epsilon_transition(remain_accept, remain.start)
          nfa.add_epsilon_transition(remain_accept, accept_state)
        end
        nfa
      end

      def to_nfa_optional(state)
        child_nfa = @child.to_nfa(state)
        start_state = state.new_state
        accepts = child_nfa.accept.dup << start_state

        nfa = Automaton::NFA.new(start_state, accepts)
        nfa.merge_transitions(child_nfa)
        nfa.add_epsilon_transition(start_state, child_nfa.start)
        nfa
      end
    end
  end
end
