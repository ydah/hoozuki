# frozen_string_literal: true

require_relative 'dfa/builder'

module Hoozuki
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
          Builder.new(nfa, use_cache).call
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
