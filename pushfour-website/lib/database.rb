require 'sqlite3'
require_relative 'common.rb'

module Pushfour
  module Database
    extend self

    DB_FILE = File.expand_path(File.join(Pushfour::Common::PROJ_ROOT, '../db/p4web.db'))

    PLAYER_TABLE = 'Players'
    GAME_TABLE = 'Games'
    BOARD_TABLE = 'Boards'
    MOVE_TABLE = 'Moves'

    def db_file(new_path = nil)
      @@database_path ||= DB_FILE
      @@database_path = new_path if new_path
      @@database_path
    end

    def create(opts = {})
      silent = opts[:silent]
      db_location ||= db_file
      exception = nil

      puts "Writing database file at #{db_location}" unless silent

      begin
        db = SQLite3::Database.open db_location

        db.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{PLAYER_TABLE}(
            Id INTEGER PRIMARY KEY,
            PassHash VARCHAR(32),
            Created INTEGER DEFAULT CURRENT_TIMESTAMP,
            LastLogin INTEGER DEFAULT CURRENT_TIMESTAMP,
            Name VARCHAR(255));
        SQL

        db.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{GAME_TABLE}(
            Id INTEGER PRIMARY KEY,
            Created INTEGER DEFAULT CURRENT_TIMESTAMP,
            Updated INTEGER DEFAULT CURRENT_TIMESTAMP,
            Player1 INTEGER,
            Player2 INTEGER,
            Status INTEGER,
            Turn INTEGER,
            Board INTEGER)
        SQL

        db.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{BOARD_TABLE}(
            Id INTEGER PRIMARY KEY,
            Width INTEGER,
            Height INTEGER,
            Created INTEGER DEFAULT CURRENT_TIMESTAMP,
            BoardString VARCHAR(255));
        SQL

        db.execute <<-SQL
          CREATE TABLE IF NOT EXISTS #{MOVE_TABLE}(
            Id INTEGER PRIMARY KEY,
            Game INTEGER,
            MoveNumber INTEGER,
            Player INTEGER,
            XLocation INTEGER,
            YLocation INTEGER,
            MoveDate INTEGER DEFAULT CURRENT_TIMESTAMP);
        SQL
      rescue SQLite3::Exception => e
        puts 'SQLite Exception'
        puts e
        exception = e
      ensure
        db.close if db
      end

      raise exception if exception
    end

    def execute_query(query, opts = {})
      verbose = opts[:verbose]
      result = nil

      begin
        db = SQLite3::Database.open db_file

        puts "Executing: #{query}" if verbose
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

    def update(table, columns, values, id, opts = {})
      verbose = opts[:verbose]
      result = nil

      validate(columns, values)

      cols = columns.map {|c| "'#{c}'=?"}.join(', ')

      begin
        db = SQLite3::Database.open db_file

        prep = "update #{table} set #{cols} where Id=#{id};"
        puts "Prepared: #{prep}" if verbose

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

    def insert(table, columns, values, opts = {})
      verbose = opts[:verbose]
      result = nil

      validate(columns, values)

      cols = columns.map {|c| "'#{c.to_s}'"}.join(',')
      val_args = (['?'] * columns.size).join(',')

      begin
        db = SQLite3::Database.open db_file

        prep = "insert into #{table} (#{cols}) values (#{val_args});"
        puts "Prepared: #{prep}" if verbose

        ins = db.prepare prep

        puts "Inserting: #{values}" if verbose
        ins.execute(values)
        ins.close
        result = db.last_insert_row_id
        puts "Insert result: #{result}" if verbose
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

