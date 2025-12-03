# frozen_string_literal: true

class Hoozuki::Parser
rule
  target: choice

  choice:
      concatenation
    | choice PIPE concatenation {
            children = val[0].is_a?(Hoozuki::Node::Choice) ? val[0].children.dup : [val[0]]
            children << val[2]
            result = Hoozuki::Node::Choice.new(children)
          }

  concatenation:
      repetition
    | EPSILON { result = Hoozuki::Node::Epsilon.new }
    | concatenation repetition {
        if val[0].is_a?(Hoozuki::Node::Epsilon)
          result = val[1]
        else
          children = val[0].is_a?(Hoozuki::Node::Concatenation) ? val[0].children.dup : [val[0]]
          children << val[1]
          result = Hoozuki::Node::Concatenation.new(children)
        end
      }

  repetition:
      group
    | group STAR { result = Hoozuki::Node::Repetition.new(val[0], :zero_or_more) }
    | group PLUS { result = Hoozuki::Node::Repetition.new(val[0], :one_or_more) }
    | group QUESTION { result = Hoozuki::Node::Repetition.new(val[0], :optional) }

  group:
      LPAREN choice RPAREN { result = val[1] }
    | literal

  literal:
      CHAR { result = Hoozuki::Node::Literal.new(val[0]) }

end

---- header
require_relative 'node'

---- inner
  def initialize
    @yydebug = true if ENV['DEBUG']
  end

  def parse(pattern)
    @pattern = pattern
    @offset = 0
    @tokens = []
    tokenize
    do_parse
  end

  private

  ESCAPABLE_CHARS = ['(', ')', '|', '*', '+', '?', '\\'].freeze
  SPECIAL_TOKENS = {
    '(' => :LPAREN,
    ')' => :RPAREN,
    '|' => :PIPE,
    '*' => :STAR,
    '+' => :PLUS,
    '?' => :QUESTION
  }.freeze

  def tokenize
    while @offset < @pattern.length
      char = @pattern[@offset]

      if char == '\\'
        handle_escape_sequence
      elsif SPECIAL_TOKENS.key?(char)
        handle_special_char(char)
      else
        add_token(:CHAR, char)
      end
    end

    @tokens << [false, false]
  end

  def handle_escape_sequence
    @offset += 1
    raise 'Unexpected end of pattern' if @offset >= @pattern.length

    escaped = @pattern[@offset]
    raise "Invalid escape sequence: \\#{escaped}" unless ESCAPABLE_CHARS.include?(escaped)

    add_token(:CHAR, escaped)
  end

  def handle_special_char(char)
    token_type = SPECIAL_TOKENS[char]
    add_token(token_type, char)

    insert_epsilon_after_lparen if char == '(' && next_char == '|'
    insert_epsilon_after_pipe if char == '|' && should_insert_epsilon_after_pipe?
  end

  def should_insert_epsilon_after_pipe?
    next_char.nil? || [')', '|'].include?(next_char)
  end

  def insert_epsilon_after_lparen
    @tokens << [:EPSILON, nil]
  end

  def insert_epsilon_after_pipe
    @tokens << [:EPSILON, nil]
  end

  def add_token(type, value)
    @tokens << [type, value]
    @offset += 1
  end

  def next_char
    @offset < @pattern.length ? @pattern[@offset] : nil
  end

  def next_token
    @tokens.shift
  end
