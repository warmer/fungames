require_relative 'common.rb'
require_relative 'player.rb'

module Pushfour
  module Website
    class Registration
      extend Common

      def self.register(params)
        # save here so the form may be re-populated with the given name
        name = sanitized_name(params[:name])
        errors = []
        begin
          player = Player.new(params)
          name = player.name
        rescue => e
          errors << e.message
        end

        {errors: errors, name: name}
      end
    end
  end
end
