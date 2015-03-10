require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'

module Pushfour
  class Login
    extend Pushfour::Common

    def self.login(params)
      errors = []

      raw_name = params[:name]
      password = params[:password]
      id = nil

      name = sanitized_name(raw_name)
      if password and password.size > 0
        if name.size > 0 and name == raw_name
          pw_hash = md5sum(name + password)
          res = Pushfour::Database.execute_query <<-HERE
            SELECT id from #{Pushfour::Database::PLAYER_TABLE}
            WHERE name LIKE '#{name}' AND passhash LIKE '#{pw_hash}';
          HERE
          if res.size > 0
            id = res[0][0]
          else
            errors << 'Could not not find a user with the given credentials'
          end
        elsif name.size > 0
          errors << 'Name contained illegal characters'
        else
          errors << 'Please provide provide ame'
        end
      else
        errors << 'Must enter a password'
      end

      {errors: errors, name: name, id: id}
    end

  end
end
