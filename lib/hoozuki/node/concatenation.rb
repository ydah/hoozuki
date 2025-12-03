# frozen_string_literal: true

module Hoozuki
  module Node
    class Concatenation
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def to_nfa(state)
        nfas = @children.map { |child| child.to_nfa(state) }
        nfa = nfas.first

        nfas.drop(1).each do |next_nfa|
          nfa.merge_transitions(next_nfa)
          nfa.accept.each do |accept_state|
            nfa.add_epsilon_transition(accept_state, next_nfa.start)
          end
          nfa.accept = next_nfa.accept
        end

        nfa
      end
    end
  end
end
