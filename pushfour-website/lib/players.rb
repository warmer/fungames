require_relative 'common.rb'
require_relative 'player.rb'

module Pushfour
  module Website
    class Players
      extend Common

      def self.info_for(player_id)
        info = nil
        player = Player.new(id: player_id) rescue nil
        info = {id: player.id, name: player.name} if player
        info
      end

      def self.player_list(params)
        errors = []
        player_info = {players:[], limit: nil, start: nil}
        begin
          player_info = Player.list(params)
        rescue => e
          errors << e.message
        end

        player_info[:players] = player_info[:players].map{|p| {id: p.id, name: p.name}}

        {errors: errors}.merge(player_info)
      end
    end
  end
end
