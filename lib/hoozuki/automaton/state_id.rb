# frozen_string_literal: true

class Hoozuki
  module Automaton
    class StateID
      def initialize(id)
        @id = id
      end

      class << self
        def new_state
          @id += 1
          StateID.new(@id)
        end
      end

      def new_state
        @id += 1
        StateID.new(@id)
      end
    end
  end
end
