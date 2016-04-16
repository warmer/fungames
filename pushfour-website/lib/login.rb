require_relative 'common.rb'
require_relative 'player.rb'

module Pushfour
  module Website
    class Login
      extend Pushfour::Website::Common

      def self.login(params)
        errors = []
        password = name = player = id = nil

        raw_name = params.delete(:name) || ''
        errors << 'Please provide a username' if raw_name.empty?

        if errors.empty?
          name = sanitized_name(raw_name)
          errors << 'Name contained illegal characters' unless name == raw_name
        end

        if errors.empty?
          password = params.delete(:password) || ''
          errors << 'Please provide a password' if password.empty?
        end

        if errors.empty?
          player = Player.with(name, password)
          errors << 'Could not not find a user with the given credentials' unless player
        end

        id = player.id if errors.empty?

        {errors: errors, name: name, id: id}
      end
    end
  end
end
