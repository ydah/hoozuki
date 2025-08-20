# frozen_string_literal: true

class Hoozuki
  module Automaton
    class DFA
      attr_reader :start, :accept, :transitions

      def initialize(start, accept)
        @start = start
        @accept = accept
        @transitions = Set.new
        @cache = {}
      end

      class << self
        def from_nfa(nfa, use_cache)
          dfa_states = {}
          queue = []
          nfa_accept_set = nfa.accept.to_set

          start_set = Set.new([nfa.start])
          start_states = nfa.epsilon_closure(start_set)

          start_id = 0
          dfa_states[start_states] = start_id
          queue << start_states

          dfa = new(start_id, Set.new)

          while (current_nfa_states = queue.shift)
            current_dfa_id = dfa_states[current_nfa_states]
            dfa.accept.merge([current_dfa_id]) if current_nfa_states.any? { |state| nfa_accept_set.include?(state) }

            transitions_map = Hash.new { |h, k| h[k] = Set.new }

            current_nfa_states.each do |state|
              nfa.transitions.each do |from, label, to|
                transitions_map[label].merge(nfa.epsilon_closure(Set[to])) if from == state && !label.nil?
              end
            end

            transitions_map.each do |char, next_nfa_states|
              unless dfa_states.key?(next_nfa_states)
                next_dfa_id = dfa_states.length
                dfa_states[next_nfa_states] = next_dfa_id
                queue.push(next_nfa_states)
              end

              next_dfa_id = dfa_states[next_nfa_states]
              dfa.transitions.add([current_dfa_id, char, next_dfa_id])

              dfa.cache[[current_dfa_id, char]] = next_dfa_id if use_cache
            end
          end

          dfa
        end
      end

      def next_transition(current, input, use_cache)
        if use_cache && (next_state = @cache[[current, input]])
          return next_state
        end

        @transitions.find { |from, label, _| from == current && label == input }&.last
      end

      def match?(input, use_cache)
        state = @start

        input.each_char do |char|
          next_state = next_transition(state, char, use_cache)
          return false unless next_state

          state = next_state
        end

        @accept.include?(state)
      end
    end
  end
end
