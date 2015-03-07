require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'

module Pushfour
  class Login
    extend Pushfour::Common

    def self.login(params)
      errors = []

      raw_name = params['name']
      password = params['password']

      name = sanitized_name(raw_name)
      if name.size > 0 and name == raw_name
        pw_hash = md5sum(name + password)
        res = Pushfour::Database.execute_query <<-HERE
          SELECT name from #{Pushfour::Database::PLAYER_TABLE}
          WHERE name='#{name}' AND passhash='#{pw_hash}';
        HERE
        res.size > 0
      elsif name.size > 0
        errors << 'Name contained illegal characters'
      else
        errors << 'Please enter your login name'
      end

      errors << 'Name cannot be empty' unless name and name.size > 0
      errors << 'Must enter a password' unless password
      errors << 'Passwords must match' unless password == password2

      errors << "Name '#{name}' is in use" if name and name_in_use?(name)

      unless errors.size > 0
        res = Pushfour::Database.insert(
          Pushfour::Database::PLAYER_TABLE,
          ['name', 'passhash'],
          [name, md5sum(name + password)]
        )
        puts res
      end

      {errors: errors, name: name}
    end

  end
end
