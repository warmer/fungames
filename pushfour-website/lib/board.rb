require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'

module Pushfour
  module Website
    class Board
      include Common

      attr_reader :id, :width, :height, :board_string

      def initialize(params)
        @id = val_if_int(params.delete(:id))

        if @id
          if params.size > 0
            raise ArgumentError, "Given game ID, too many params: #{params.keys.sort}"
          end

          load_board
        else
          @height = val_if_int(params.delete(:height))
          @width = val_if_int(params.delete(:width))
          @obstacles = val_if_int(params.delete(:obstacles)) || 4
          # test hook for creating deterministic output
          @rand_seed = val_if_int(params.delete(:rand_seed))
          @rand = (@rand_seed ? Random.new(@rand_seed) : Random.new)

          if params.size > 0
            raise ArgumentError, "Given game ID, too many params: #{params.keys.sort}"
          end

          create_board
        end
        # TODO: think through this flag more
        @persisted = false

        load_board if @id and @id > 0
      end

      # returns true if this game is persisted to the datbase
      def persisted?
        return @persisted
      end

      # persists this game to database
      def persist!
        # TODO: persist
        @persisted = true
      end

      private

      def create_board
        space_count = @height * @width
        ob_count = [space_count / 4, @obstacles].min
        #notes << "Obstacle count reduced to #{ob_count}" unless ob_count == @obstacles
        @obstacles = ob_count
        blocks = (0...space_count).to_a.sample(ob_count, random: @rand)
        @board_string = '+' * space_count
        blocks.each do |idx|
          @board_string[idx] = '#'
        end
        @id = Database.insert(
          Database::BOARD_TABLE,
          [:width, :height, :boardstring],
          [@width, @height, @board_string]
        )
        if not @id or @id <= 0
          raise 'Could not insert board into database'
        end
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
