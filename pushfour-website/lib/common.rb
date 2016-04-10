require 'sqlite3'
require 'digest/md5'

module Pushfour
  module Common
    PROJ_ROOT = File.dirname(__FILE__)

    GAME_STATUS = {
      0 => :in_progress,
      1 => :stalemate,
      2 => :ended,
      3 => :abandoned,
    }

    def status_id_for(sym)
      status_id = nil
      GAME_STATUS.each do |id, status|
        if status == sym
          status_id = id
          break
        end
      end
      return status_id
    end

    def status_for(id)
      GAME_STATUS[id].capitalize
    end

    def md5sum(str)
      Digest::MD5.hexdigest(str)
    end

    def sanitized_name(name)
      name ||= ''
      # a-zA-Z0-9_-
      name.gsub(/[^a-zA-Z0-9_-]/, '')
    end

    def val_if_int(raw)
      parsed = raw.to_i
      (raw.to_s == parsed.to_s ? parsed : nil)
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
