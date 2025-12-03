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
        def new_from_node(node, state)
          raise ArgumentError, 'Node cannot be nil' if node.nil?

          case node
          when Node::Literal then to_literal_nfa(node, state)
          when Node::Epsilon then to_epsilon_nfa(state)
          when Node::Repetition then to_repetition_nfa(node, state)
          when Node::Choice then to_choice_nfa(node, state)
          when Node::Concatenation then to_concatenation_nfa(node, state)
          else
            raise ArgumentError, "Unsupported node type: #{node.class}"
          end
        end

        private

        def to_literal_nfa(node, state)
          start_state = state.new_state
          accept_state = state.new_state
          nfa = new(start_state, [accept_state])
          nfa.add_transition(start_state, node.value, accept_state)
          nfa
        end

        def to_epsilon_nfa(state)
          start_state = state.new_state
          accept_state = state.new_state
          nfa = new(start_state, [accept_state])
          nfa.add_epsilon_transition(start_state, accept_state)
          nfa
        end

        def to_repetition_nfa(node, state)
          if node.zero_or_more?
            to_zero_or_more_nfa(node.child, state)
          elsif node.one_or_more?
            to_one_or_more_nfa(node.child, state)
          elsif node.optional?
            to_optional_nfa(node.child, state)
          end
        end

        def to_zero_or_more_nfa(child_node, state)
          child_nfa = new_from_node(child_node, state)
          start_state = state.new_state
          accepts = child_nfa.accept.dup << start_state

          nfa = new(start_state, accepts)
          nfa.merge_transitions(child_nfa)
          nfa.add_epsilon_transition(start_state, child_nfa.start)

          connect_accepts_to_start(nfa, child_nfa.accept, child_nfa.start)
          nfa
        end

        def to_one_or_more_nfa(child_node, state)
          child_nfa = new_from_node(child_node, state)
          start_state = state.new_state
          accept_state = state.new_state

          nfa = new(start_state, [accept_state])
          nfa.merge_transitions(child_nfa)
          nfa.add_epsilon_transition(start_state, child_nfa.start)

          child_nfa.accept.each do |child_accept|
            nfa.add_epsilon_transition(child_accept, child_nfa.start)
            nfa.add_epsilon_transition(child_accept, accept_state)
          end

          nfa
        end

        def to_optional_nfa(child_node, state)
          child_nfa = new_from_node(child_node, state)
          start_state = state.new_state
          accepts = child_nfa.accept.dup << start_state

          nfa = new(start_state, accepts)
          nfa.merge_transitions(child_nfa)
          nfa.add_epsilon_transition(start_state, child_nfa.start)
          nfa
        end

        def to_choice_nfa(node, state)
          left_child, right_child = node.children
          left_nfa = new_from_node(left_child, state)
          right_nfa = new_from_node(right_child, state)

          start_state = state.new_state
          accepts = left_nfa.accept | right_nfa.accept

          nfa = new(start_state, accepts)
          nfa.merge_transitions(left_nfa)
          nfa.merge_transitions(right_nfa)
          nfa.add_epsilon_transition(start_state, left_nfa.start)
          nfa.add_epsilon_transition(start_state, right_nfa.start)
          nfa
        end

        def to_concatenation_nfa(node, state)
          nfas = node.children.map { |child| new_from_node(child, state) }
          nfa = nfas.first

          nfas.drop(1).each do |next_nfa|
            nfa.merge_transitions(next_nfa)
            connect_accepts_to_start(nfa, nfa.accept, next_nfa.start)
            nfa.accept = next_nfa.accept
          end

          nfa
        end

        def connect_accepts_to_start(nfa, accept_states, start_state)
          accept_states.each do |accept_state|
            nfa.add_epsilon_transition(accept_state, start_state)
          end
        end
      end

      def epsilon_closure(start)
        closure = calculate_epsilon_closure(start.to_set)
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

      def calculate_epsilon_closure(start_states)
        visited = Set.new
        to_visit = start_states.to_a

        until to_visit.empty?
          state = to_visit.shift
          next if visited.include?(state)

          visited << state

          epsilon_transitions_from(state).each do |target_state|
            to_visit << target_state unless visited.include?(target_state)
          end
        end

        visited
      end

      def epsilon_transitions_from(state)
        transitions.each_with_object([]) do |(from, label, to), result|
          result << to if from == state && label.nil?
        end
      end
    end
  end
end
