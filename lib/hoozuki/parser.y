# frozen_string_literal: true

class Hoozuki::Parser
rule
  target: choice

  choice:
      concatenation
    | choice PIPE concatenation {
            children = []
            if val[0].is_a?(Hoozuki::Node::Choice)
              children.concat(val[0].children)
            else
              children << val[0]
            end
            children << val[2]
            result = Hoozuki::Node::Choice.new(children)
          }

  concatenation:
      repetition
    | EPSILON { result = Hoozuki::Node::Epsilon.new }
    | concatenation repetition {
        children = []
        if val[0].is_a?(Hoozuki::Node::Epsilon)
          result = val[1]
        elsif val[0].is_a?(Hoozuki::Node::Concatenation)
          children.concat(val[0].children)
          children << val[1]
          result = Hoozuki::Node::Concatenation.new(children)
        else
          children << val[0]
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

  def tokenize
    while @offset < @pattern.length
      char = @pattern[@offset]

      case char
      when '\\'
        @offset += 1
        raise 'Unexpected end of pattern' if @offset >= @pattern.length

        escaped = @pattern[@offset]
        case escaped
        when '(', ')', '|', '*', '+', '?', '\\'
          @tokens << [:CHAR, escaped]
        else
          raise "Invalid escape sequence: \\#{escaped}"
        end
        @offset += 1
      when '('
        @tokens << [:LPAREN, char]
        @offset += 1
        # Insert EPSILON token if PIPE immediately follows LPAREN
        if @offset < @pattern.length && @pattern[@offset] == '|'
          @tokens << [:EPSILON, nil]
        end
      when ')'
        @tokens << [:RPAREN, char]
        @offset += 1
      when '|'
        @tokens << [:PIPE, char]
        @offset += 1
        # Insert EPSILON token if PIPE is followed by RPAREN, EOF, or another PIPE
        if @offset >= @pattern.length || @pattern[@offset] == ')' || @pattern[@offset] == '|'
          @tokens << [:EPSILON, nil]
        end
      when '*'
        @tokens << [:STAR, char]
        @offset += 1
      when '+'
        @tokens << [:PLUS, char]
        @offset += 1
      when '?'
        @tokens << [:QUESTION, char]
        @offset += 1
      else
        @tokens << [:CHAR, char]
        @offset += 1
      end
    end

    @tokens << [false, false]  # EOF marker
  end

  def next_token
    @tokens.shift
  end
