# frozen_string_literal: true

require 'sorted_set'

module Hoozuki
  module Automaton
    class NFA
      attr_accessor :start, :accept, :transitions

      def initialize(start, accept)
        @start = start
        @accept = accept
        @transitions = Set.new
      end

      class << self
        def from_node(node, state)
          raise ArgumentError, 'Node cannot be nil' if node.nil?

          node.to_nfa(state)
        end
      end

      def epsilon_closure(start)
        closure = compute_closure(start.to_set)
        ::SortedSet.new(closure)
      end

      def merge_transitions(other)
        @transitions.merge(other.transitions)
      end

      def add_epsilon_transition(from, to)
        @transitions << [from, nil, to]
      end

      def add_transition(from, char, to)
        @transitions << [from, char, to]
      end

      private

      def compute_closure(start_states)
        visited = Set.new
        to_visit = start_states.to_a

        until to_visit.empty?
          state = to_visit.shift
          next if visited.include?(state)

          visited << state

          epsilon_from(state).each do |target_state|
            to_visit << target_state unless visited.include?(target_state)
          end
        end

        visited
      end

      def epsilon_from(state)
        transitions.each_with_object([]) do |(from, label, to), result|
          result << to if from == state && label.nil?
        end
      end
    end
  end
end
