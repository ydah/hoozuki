# frozen_string_literal: true

require_relative 'hoozuki/automaton'
require_relative 'hoozuki/node'
require_relative 'hoozuki/parser'
require_relative 'hoozuki/version'

class Hoozuki
  def initialize(input, method: :dfa)
    @input = input
    @method = method

    ast = Hoozuki::Parser.new(input).parse
    case method
    when :dfa
      nfa = Automaton::NFA.new_from_node(ast, Automaton::StateID.new(0))
      @dfa = Automaton::DFA.from_nfa(nfa, use_cache?(input))
    end
  end

  def match?(input)
    case @method
    when :dfa
      @dfa.match?(input, use_cache?(input))
    else
      raise ArgumentError, "Unknown method: #{@method}"
    end
  end

  private

  def use_cache?(input)
    input.length > 1000
  end
end
