require 'sqlite3'
require 'digest/md5'

module Pushfour
  module Common
    PROJ_ROOT = File.dirname(__FILE__)
    DB_FILE = File.join(PROJ_ROOT, 'db/p4web.db')

    PLAYER_TABLE = 'Players'
    GAME_TABLE = 'Games'
    BOARD_TABLE = 'Boards'
    MOVE_TABLE = 'Moves'

    def md5sum(str)
      Digest::MD5.hexdigest(str)
    end

    def sanitized_name(name)
      # a-zA-Z0-9_-
      name.gsub(/[^a-zA-Z0-9_-]/, '') if name
    end

    def db_file
      DB_FILE
    end

    def execute_query(query)
      result = nil

      begin
        db = SQLite3::Database.open db_file

        puts "Executing: #{query}"
        result = db.execute query
      rescue SQLite3::Exception => e
        puts 'SQLite Exception'
        puts e
        exception = e
      ensure
        db.close if db
      end

      raise exception if exception

      result
    end

    def validate(columns, values)
      raise 'columns not an array' unless columns.is_a? Array
      raise 'values not an array' unless values.is_a? Array
      raise 'column count not equal to value count' unless columns.size == values.size

    end

    def update(table, columns, values, id)
      result = nil

      validate(columns, values)

      cols = columns.map {|c| "'#{c}'=?"}.join(', ')

      begin
        db = SQLite3::Database.open db_file

        prep = "update #{table} set #{cols} where Id=#{id};"
        puts "Prepared: #{prep}"

        statement = db.prepare prep
        statement.execute(values)
        statement.close
        result = id
      rescue SQLite3::Exception => e
        puts 'SQLite Exception'
        puts e
        exception = e
      rescue => e
        puts 'Generic exception:'
        puts e
        exception = e
      ensure
        db.close if db
      end

      raise exception if exception

      result
    end

    def insert(table, columns, values)
      result = nil

      validate(columns, values)

      cols = columns.map {|c| "'#{c}'"}.join(',')
      val_args = (['?'] * columns.size).join(',')

      begin
        db = SQLite3::Database.open db_file

        prep = "insert into #{table} (#{cols}) values (#{val_args});"
        puts "Prepared: #{prep}"

        ins = db.prepare prep

        puts "Inserting: #{values}"
        ins.execute(values)
        ins.close
        result = db.last_insert_row_id
        puts "Insert result: #{result}"
      rescue SQLite3::Exception => e
        puts 'SQLite Exception'
        puts e
        exception = e
      ensure
        db.close if db
      end

      raise exception if exception

      result
    end


  end
end
