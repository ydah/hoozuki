# frozen_string_literal: true

class Hoozuki
  class Parser
    def initialize(pattern)
      @pattern = pattern
      @offset = 0
    end

    class << self
      def parse(pattern)
        new(pattern).parse
      end
    end

    def parse
      ast = parse_choice

      raise 'Unexpected end of pattern' unless eol?

      ast
    end

    private

    def current
      @pattern[@offset]
    end

    def eol?
      @pattern.size <= @offset
    end

    def next_char
      @offset += 1
    end

    def parse_choice
      children = []
      children << parse_concatenation

      while current == '|'
        next_char
        children << parse_concatenation
      end

      return children.first if children.size == 1

      Hoozuki::Node::Choice.new(children)
    end

    def parse_concatenation
      children = []

      children << parse_repetition until stop_parsing_concatenation?

      return children.first if children.size == 1

      Hoozuki::Node::Concatenation.new(children)
    end

    def stop_parsing_concatenation?
      eol? || current == '|' || current == ')'
    end

    def parse_repetition
      child = parse_group

      quantifier = nil
      case current
      when '*'
        quantifier = :zero_or_more
      when '+'
        quantifier = :one_or_more
      when '?'
        quantifier = :optional
      end
      return child if quantifier.nil?

      next_char

      Hoozuki::Node::Repetition.new(child, quantifier)
    end

    def parse_group
      return parse_literal if current != '('

      next_char
      child = parse_choice
      raise 'Expected closing parenthesis' unless current == ')'

      next_char
      child
    end

    def parse_literal
      raise 'Unexpected end of pattern' if eol?

      if current == '\\'
        next_char
        raise 'Unexpected end of pattern' if eol?

        value = current
        case value
        when '(', ')', '|', '*', '+', '?', '\\'
          next_char
        else
          raise "Invalid escape sequence: \\#{value}"
        end

        return Hoozuki::Node::Literal.new(value)
      end

      value = current
      case value
      when '(', ')', '|', '*', '+', '?', '\\'
        raise "Unexpected character: #{value}"
      else
        next_char
      end

      Hoozuki::Node::Literal.new(value)
    end
  end
end
