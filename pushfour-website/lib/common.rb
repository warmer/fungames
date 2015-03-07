require 'sqlite3'
require 'digest/md5'

module Pushfour
  module Common
    PROJ_ROOT = File.dirname(__FILE__)

    def md5sum(str)
      Digest::MD5.hexdigest(str)
    end

    def sanitized_name(name)
      name ||= ''
      # a-zA-Z0-9_-
      name.gsub(/[^a-zA-Z0-9_-]/, '')
    end

    def url_replace(map, key, opts = {})
      u = map[key]

      if opts
        opts.each do |sym, val|
          u = u.gsub(/\/:#{sym.to_s}($|[^a-z0-9_])/, "/#{val.to_s}\\1")
        end
      end

      u
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
