#!/usr/bin/env ruby

#
# This was NOT designed to protect against malicious requests.
#
# No warranty, express or implied, whatsoever.
#

require_relative 'common.rb'
include Pushfour::Common

def create_db
  exception = nil

  begin
    db = SQLite3::Database.open db_file

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
        Player1 INTEGER,
        Player2 INTEGER,
        Status INTEGER,
        Turn INTEGER,
        Board INTEGER,
        Name VARCHAR(255));
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
        MoveNumber INTEGER,
        Player INTEGER,
        XLocation INTEGER,
        YLocation INTEGER,
        MoveDate INTEGER DEFAULT CURRENT_TIMESTAMP);
    SQL

#    db.execute <<-SQL
#      CREATE TABLE IF NOT EXISTS #{BUDGET_TABLE}(
#        Id INTEGER PRIMARY KEY,
#        PeriodDays INT,
#        StartDate DATE,
#        EndDate DATE,
#        Created DATE,
#        Updated DATE,
#        Tag INT,
#        Amount INT,
#        Name VARCHAR(255));
#    SQL
#
#    db.execute <<-SQL
#      CREATE TABLE IF NOT EXISTS #{EXPENSE_TAG_TABLE}(
#        Id INTEGER PRIMARY KEY,
#        Tag INT,
#        Expense INT);
#    SQL
  rescue SQLite3::Exception => e
    puts 'SQLite Exception'
    puts e
    exception = e
  ensure
    db.close if db
  end

  raise exception if exception
end


if __FILE__ == $0
  puts 'Creating the database...'
  create_db
  puts 'Database created!'
end
