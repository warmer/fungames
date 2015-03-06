require 'sqlite3'
require 'digest/md5'

module Pushfour
  module Common
    PROJ_ROOT = File.dirname(__FILE__)

    def md5sum(str)
      Digest::MD5.hexdigest(str)
    end

    def sanitized_name(name)
      # a-zA-Z0-9_-
      name.gsub(/[^a-zA-Z0-9_-]/, '') if name
    end

    def filter(params, keys = [])
      res = {}

      keys.each do |k|
        key = k.to_s
        res[k] = params[key] if params[key]
      end

      res
    end

  end
end
