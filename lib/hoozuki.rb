# frozen_string_literal: true

require_relative 'hoozuki/automaton'
require_relative 'hoozuki/instruction'
require_relative 'hoozuki/node'
require_relative 'hoozuki/parser'
require_relative 'hoozuki/version'
require_relative 'hoozuki/vm'

module Hoozuki
  module_function

  def compile(input, engine: :dfa)
    ast = Parser.new.parse(input)
    case engine
    when :dfa
      nfa = Automaton::NFA.new_from_node(ast, Automaton::StateID.new(0))
      Automaton::DFA.from_nfa(nfa, use_cache?(input))
    when :vm
      compiler = VM::Compiler.new
      compiler.compile(ast)
      compiler.instructions
    else
      raise ArgumentError, "Unknown engine: #{engine}"
    end
  end

  def match?(pattern, input, engine: :dfa)
    compiled = compile(pattern, engine: engine)
    case engine
    when :dfa
      compiled.match?(input, use_cache?(input))
    when :vm
      VM::Evaluator.evaluate(compiled, input, 0, 0)
    end
  end

  def use_cache?(input)
    input.length > 1000
  end
  private_class_method :use_cache?
end
