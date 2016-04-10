require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'
require_relative 'players.rb'
require_relative 'create_game.rb'
require_relative '../../pushfour-ai/common.rb'

module Pushfour
  class WebGame
    extend Pushfour::Common

    def self.list(params)
      errors = []
      games = []
      players = {}

      start = val_if_int(params[:start])
      start = 0 unless start and start > 0

      res = Pushfour::Database.execute_query <<-HERE
        SELECT id,player1,player2,turn,status,board
        FROM #{Pushfour::Database::GAME_TABLE}
        ORDER BY id ASC
        LIMIT 50
        OFFSET #{start}
      HERE
      if res.size > 0
        res.each do |p|
          player1 = players[p[1]]
          player2 = players[p[2]]

          player1 ||= Pushfour::Players.info_for(p[1])
          player2 ||= Pushfour::Players.info_for(p[2])

          players[p[1]] = player1
          players[p[2]] = player2

          turn = player1 if p[3] == 0
          turn = player2 if p[3] == 1
          turn ||= {id: 0, name: "Player #{p[3] + 1}"}

          status = status_for(p[4])

          games << {id: p[0], player1: player1, player2: player2,
            turn: turn, status: status, board: p[5]
          }
        end
      else
        errors << 'No games found'
      end

      {games: games, errors: errors}
    end

    def self.get_status(params)
      errors = []
      turn = nil
      status = nil

      game_id = val_if_int(params[:game_id])
      errors << 'Invalid game ID' unless game_id and game_id > 0

      last_move = val_if_int(params[:last_move]) || 0

      if errors.size == 0
        res = Pushfour::Database.execute_query <<-HERE
          SELECT player1,player2,turn,status,board
          FROM #{Pushfour::Database::GAME_TABLE}
          WHERE id = #{game_id};
        HERE
        if res.size > 0
          moves = load_moves(game_id: game_id)[:moves]
          turn = res[2].to_i
          status = res[3].to_i
        else
          errors << 'Game status not found'
        end
      end

      {
        status: status,
        moves: moves,
        current_turn: turn,
        errors: errors,
       }
    end
  end
end
