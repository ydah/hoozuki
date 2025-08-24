# frozen_string_literal: true

require_relative 'hoozuki/automaton'
require_relative 'hoozuki/instruction'
require_relative 'hoozuki/node'
require_relative 'hoozuki/parser'
require_relative 'hoozuki/version'
require_relative 'hoozuki/vm'

class Hoozuki
  def initialize(input, engine: :dfa)
    @input = input
    @engine = engine

    ast = Hoozuki::Parser.new(input).parse
    case engine
    when :dfa
      nfa = Automaton::NFA.new_from_node(ast, Automaton::StateID.new(0))
      @dfa = Automaton::DFA.from_nfa(nfa, use_cache?(input))
    when :vm
      compiler = VM::Compiler.new
      compiler.compile(ast)
      @bytecode = compiler.instructions
    end
  end

  def match?(input)
    case @engine
    when :dfa
      @dfa.match?(input, use_cache?(input))
    when :vm
      VM::Evaluator.evaluate(@bytecode, input, 0, 0)
    else
      raise ArgumentError, "Unknown engine: #{@engine}"
    end
  end

  private

  def use_cache?(input)
    input.length > 1000
  end
end
