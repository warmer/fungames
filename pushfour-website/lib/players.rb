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

      def self.profile_for(player_id)
        info = nil
        player = Player.new(id: player_id) rescue nil
        info = {id: player.id, name: player.name, api_key: player.api_key} if player
        info
      end

      def self.for_key(raw_key)
        errors = {}
        api_key = sanitized_key(raw_key)
        return {errors: 'Invalid API key'} unless api_key == raw_key
        return {errors: 'Invalid API key'} unless api_key.length == 64
        player = Player.with_api_key(api_key)
        return {errors: 'Invalid API key'} unless player
        {errors: [], player: {id: player.id, name: player.name}}
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
