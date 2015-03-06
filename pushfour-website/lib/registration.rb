require 'sqlite3'
require 'digest/md5'
require_relative 'common.rb'
require_relative 'database.rb'

module Pushfour
  class Registration
    extend Pushfour::Common

    def self.name_in_use?(name)
      res = Pushfour::Database.execute_query <<-HERE
        SELECT name from #{Pushfour::Database::PLAYER_TABLE} WHERE name='#{name}';
      HERE
      res.size > 0
    end

    def self.register(params)
      raw_name = params['name']
      password = params['password']
      password2 = params['password2']

      name = sanitized_name(raw_name)

      errors = []

      errors << 'Name contained illegal characters' if name != raw_name
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
