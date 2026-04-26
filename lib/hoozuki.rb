# frozen_string_literal: true

require_relative 'hoozuki/automaton'
require_relative 'hoozuki/instruction'
require_relative 'hoozuki/node'
require_relative 'hoozuki/parser'
require_relative 'hoozuki/version'
require_relative 'hoozuki/vm'

module Hoozuki
  class Pattern
    def initialize(pattern, engine: :dfa)
      @engine = engine
      @compiled = Hoozuki.compile(pattern, engine: engine)
    end

    def match?(input)
      case @engine
      when :dfa
        @compiled.match?(input, Hoozuki.__send__(:use_cache?, input))
      when :vm
        Hoozuki::VM::Evaluator.evaluate(@compiled, input, 0, 0)
      else
        raise ArgumentError, "Unknown engine: #{@engine}"
      end
    end
  end

  module_function

  def new(pattern, engine: :dfa)
    Pattern.new(pattern, engine: engine)
  end

  def compile(input, engine: :dfa)
    ast = Parser.new.parse(input)
    case engine
    when :dfa
      nfa = Automaton::NFA.from_node(ast, Automaton::StateID.new(0))
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
    new(pattern, engine: engine).match?(input)
  end

  def use_cache?(input)
    input.length > 1000
  end
  private_class_method :use_cache?
end
