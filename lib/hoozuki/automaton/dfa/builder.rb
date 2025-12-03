# frozen_string_literal: true

module Hoozuki
  module Automaton
    class DFA
      class Builder
        def initialize(nfa, use_cache)
          @nfa = nfa
          @use_cache = use_cache
          @dfa_states = {}
          @queue = []
          @nfa_accept_set = nfa.accept.to_set
        end

        def call
          initialize_dfa
          process_states
          @dfa
        end

        private

        def initialize_dfa
          start_states = @nfa.epsilon_closure(Set.new([@nfa.start]))
          start_id = 0
          @dfa_states[start_states] = start_id
          @queue << start_states
          @dfa = DFA.new(start_id, Set.new)
        end

        def process_states
          while (current_nfa_states = @queue.shift)
            current_dfa_id = @dfa_states[current_nfa_states]
            mark_accept(current_nfa_states, current_dfa_id)
            transitions_map = build_transitions(current_nfa_states)
            process_transitions(transitions_map, current_dfa_id)
          end
        end

        def mark_accept(nfa_states, dfa_id)
          return unless nfa_states.any? { |state| @nfa_accept_set.include?(state) }

          @dfa.accept.merge([dfa_id])
        end

        def build_transitions(nfa_states)
          transitions_map = Hash.new { |h, k| h[k] = Set.new }

          nfa_states.each do |state|
            @nfa.transitions.each do |from, label, to|
              next unless from == state && !label.nil?

              transitions_map[label].merge(@nfa.epsilon_closure(Set[to]))
            end
          end

          transitions_map
        end

        def process_transitions(transitions_map, current_dfa_id)
          transitions_map.each do |char, next_nfa_states|
            next_dfa_id = ensure_state(next_nfa_states)
            @dfa.transitions.add([current_dfa_id, char, next_dfa_id])
            @dfa.cache[[current_dfa_id, char]] = next_dfa_id if @use_cache
          end
        end

        def ensure_state(nfa_states)
          return @dfa_states[nfa_states] if @dfa_states.key?(nfa_states)

          new_id = @dfa_states.length
          @dfa_states[nfa_states] = new_id
          @queue.push(nfa_states)
          new_id
        end
      end
    end
  end
end
