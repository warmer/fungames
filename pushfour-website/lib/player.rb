require_relative 'common.rb'
require_relative 'database.rb'

module Pushfour
  module Website
    class Player
      include Common
      extend Common

      attr_reader :id, :name, :api_key

      ILLEGAL_CHARS_ERROR = <<-HERE
        User name may only contain letters, numbers, underscores, and dashes.
      HERE

      def initialize(params)
        @id = val_if_int(params.delete(:id))

        if @id
          @name = params.delete(:name)
          raise ArgumentError, "Too many params for player: #{params.keys}" unless params.empty?

          load_player unless @name
        else
          raw_name = params.delete(:name)
          password = params.delete(:password)
          password2 = params.delete(:password2)

          raise ArgumentError, "Too many params for player: #{params.keys}" unless params.empty?

          @name = sanitized_name(raw_name)

          raise ILLEGAL_CHARS_ERROR.strip if name != raw_name
          raise 'Name cannot be empty' unless name and name.size > 0
          raise "Name '#{name}' is in use" if name and Player.name_in_use?(name)
          raise 'Must enter a password' unless password
          raise 'Passwords must match' unless password == password2

          create_player(password)
        end
      end

      def self.with(raw_name, password)
        player = nil
        name = sanitized_name(raw_name)
        return nil if name.empty?

        passhash = pw_hash(salt: name, password: password)
        res = Database.execute_query <<-HERE
          SELECT id from #{Database::PLAYER_TABLE}
          WHERE name = '#{name}' AND passhash LIKE '#{passhash}';
        HERE
          #WHERE name = '#{name}' AND passhash = '#{passhash}';
        id = res[0][0] unless res.empty?
        player = Player.new(id: id) if id rescue nil
        player
      end

      def self.name_in_use?(name)
        res = Database.execute_query <<-HERE
          SELECT name from #{Database::PLAYER_TABLE} WHERE name='#{name}';
        HERE
        res.size > 0
      end

      def self.list(params)
        errors = []
        players = []
        limit = start = exclude = 0
        filter = ''

        limit = params.delete(:limit).to_i
        limit = 25 unless limit > 0
        limit = 100 unless limit < 100

        start = params.delete(:start).to_i
        start = 1 unless start > 0

        exclude = params.delete(:exclude).to_i
        filter += "AND id != #{exclude} " if exclude > 0

        raise ArgumentError, "Too many params for Player.list: #{params.keys}" unless params.empty?

        res = Database.execute_query <<-HERE
          SELECT id,name from #{Database::PLAYER_TABLE}
          WHERE id >= #{start}
          #{filter}
          ORDER BY id ASC LIMIT #{limit};
        HERE
        if res.size > 0
          res.each { |p| players << Player.new(id: p[0], name: p[1]) }
        else
          errors << 'No users found'
        end

        {players: players, limit: limit, start: start}
      end

      private

      def create_player(password)
        passhash = pw_hash(salt: @name, password: password)
        @id = Database.insert(
          Database::PLAYER_TABLE,
          ['name', 'passhash'],
          [@name, passhash]
        )
      end

      def load_player
        res = Database.execute_query <<-HERE
          SELECT name from #{Database::PLAYER_TABLE}
          WHERE id = #{@id};
        HERE
        if res.empty?
          raise 'Player not found'
        else
          p = res[0]
          @name = p[0]
        end
      end
    end
  end
end
