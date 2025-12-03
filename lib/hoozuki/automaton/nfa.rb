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

      def epsilon_closure(start_states)
        visited = start_states.dup
        queue = start_states.to_a

        while (current = queue.shift)
          destinations = @transitions.select { |from, label, _| from == current && label.nil? }.map(&:last)
          destinations.each do |dest|
            queue << dest if visited.add?(dest)
          end
        end

        ::SortedSet.new(visited)
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
    end
  end
end
