# frozen_string_literal: true

require 'sorted_set'

class Hoozuki
  module Automaton
    class NFA
      attr_reader :start, :accept, :transitions

      def initialize(start, accept)
        @start = start
        @accept = accept
        @transitions = Set.new
      end

      class << self
        def new_from_node(node, state)
          raise ArgumentError, 'Node cannot be nil' if node.nil?

          case node
          when Node::Literal
            start_state = state.new_state
            accept_state = state.new_state
            nfa = new(start_state, [accept_state])
            nfa.add_transition(start_state, node.value, accept_state)
            nfa
          when Node::Repetition
            if node.zero_or_more?
              remain = new_from_node(node.child, state)
              start_state = state.new_state
              accepts = remain.accept.dup
              accepts << start_state

              nfa = new(start_state, accepts)
              nfa.merge_nfa(remain)
              nfa.add_epsilon_transition(start_state, remain.start)

              remain.accept.each do |accept_state|
                nfa.add_epsilon_transition(accept_state, remain.start)
              end

              nfa
            elsif node.one_or_more?
              remain = new_from_node(node.child, state)
              start_state = state.new_state
              accept_state = state.new_state
              nfa = new(start_state, [accept_state])

              nfa.transitions.merge(remain.transitions)
              nfa.add_epsilon_transition(start_state, remain.start)
              remain.accept.each do |remain_accept|
                nfa.add_epsilon_transition(remain_accept, remain.start)
                nfa.add_epsilon_transition(remain_accept, accept_state)
              end
              nfa
            elsif node.optional?
              child = new_from_node(node.child, state)
              start_state = state.new_state
              accepts = child.accept.dup
              accepts << start_state

              nfa = new(start_state, accepts)
              nfa.transitions.merge(child.transitions)
              nfa.add_epsilon_transition(start_state, child.start)
              nfa
            end
          when Node::Choice
            remain1 = new_from_node(node.children[0], state)
            remain2 = new_from_node(node.children[1], state)
            start_state = state.new_state
            accepts = remain1.accept if remain1.respond_to?(:accept)
            accepts |= remain2.accept if remain2.respond_to?(:accept)
            nfa = new(start_state, accepts)
            nfa.merge_nfa(remain1)
            nfa.merge_nfa(remain2)
            nfa.add_epsilon_transition(start_state, remain1.start)
            nfa.add_epsilon_transition(start_state, remain2.start)
            nfa
          when Node::Concatenation
            first_nfa = new_from_node(node.children.first, state)
            node.children.drop(1).each_with_object(first_nfa) do |child_node, chain_nfa|
              next_nfa = new_from_node(child_node, state)
              chain_nfa.transitions.merge(next_nfa.transitions)
              chain_nfa.accept.each do |accept_state|
                chain_nfa.add_epsilon_transition(accept_state, next_nfa.start)
              end
              chain_nfa.accept.clear
              next_nfa.accept.each do |accept_state|
                chain_nfa.accept << accept_state
              end
              chain_nfa
            end
          end
        end
      end

      def epsilon_closure_with_bitset(start)
        visited = Set.new
        to_visit = []

        start.each do |state|
          to_visit << state unless visited.include?(state)
        end

        until to_visit.empty?
          state = to_visit.shift

          next if visited.include?(state)

          visited << state

          transitions.each do |from, label, to|
            to_visit << to if from == state && label.nil? && !visited.include?(to)
          end
        end

        visited
      end

      def epsilon_closure(start)
        bit_start = Set.new
        start.each do |state|
          bit_start << state
        end
        bit_result = epsilon_closure_with_bitset(bit_start)
        ::SortedSet.new(bit_result)
      end

      def add_epsilon_transition(from, to)
        @transitions << [from, nil, to]
      end

      def add_transition(from, char, to)
        @transitions << [from, char, to]
      end

      def merge_nfa(other)
        @transitions.merge(other.transitions)
        add_epsilon_transition(@start, other.start)
        other.accept.each do |accept_state|
          @accept << accept_state
        end
      end
    end
  end
end
