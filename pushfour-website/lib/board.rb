require_relative 'common.rb'
require_relative 'database.rb'

module Pushfour
  module Website
    class Board
      include Common

      attr_reader :id, :width, :height, :board_string, :persisted

      def initialize(params)
        @id = val_if_int(params.delete(:id))

        if @id
          raise ArgumentError, "Too many params for board: #{params.keys.sort}" if params.size > 0

          load_board
        else
          @height = val_if_int(params.delete(:height))
          @width = val_if_int(params.delete(:width))
          @obstacles = val_if_int(params.delete(:obstacles)) || 4
          # test hook for creating deterministic output
          @rand_seed = val_if_int(params.delete(:rand_seed))
          @rand = (@rand_seed ? Random.new(@rand_seed) : Random.new)
          @persisted = params.delete(:persisted)
          @persisted = false if @persisted.nil?

          raise ArgumentError, "Too many params for board: #{params.keys.sort}" if params.size > 0

          create_board
        end

        load_board if @id and @id > 0
      end

      private

      def create_board
        space_count = @height * @width
        ob_count = [space_count / 4, @obstacles].min
        blocks = (0...space_count).to_a.sample(ob_count, random: @rand)
        @board_string = '+' * space_count
        blocks.each {|idx| @board_string[idx] = '#'}
        persist
      end

      def persist
        @id = Database.insert(
          Database::BOARD_TABLE,
          [:width, :height, :boardstring],
          [@width, @height, @board_string]
        )
        raise 'Could not insert board into database' unless @id and @id > 0
      end

      def load_board
        res = Database.execute_query <<-HERE
          SELECT width,height,boardstring
          FROM #{Database::BOARD_TABLE}
          WHERE id = #{@id};
        HERE

        if res.size > 0
          b = res[0]
          @width = b[0]
          @height = b[1]
          @board_string = b[2]
        else
          raise ArgumentError, 'Could not find the board'
        end
      end
    end
  end
end
