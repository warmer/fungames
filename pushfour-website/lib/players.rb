require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'

module Pushfour
  class Players
    extend Pushfour::Common

    def self.player_list(params)
      errors = []
      players = []
      limit = start = 0

      limit = params[:limit].to_i if params[:limit]
      limit = 25 unless limit > 0
      limit = 100 unless limit < 100

      start = params[:start].to_i if params[:start]
      start = 1 unless start > 0

      res = Pushfour::Database.execute_query <<-HERE
        SELECT id,name from #{Pushfour::Database::PLAYER_TABLE}
        WHERE id >= #{start}
        ORDER BY id ASC LIMIT #{limit};
      HERE
      if res.size > 0
        res.each do |p|
          players << {id: p[0], name: p[1]}
        end
      else
        errors << 'No users found'
      end

      unless errors.size > 0
      end

      {errors: errors, players: players, limit: limit, start: start}
    end

  end
end
