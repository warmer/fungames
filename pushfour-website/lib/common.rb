require 'digest/md5'
require 'openssl'

module Pushfour
  module Website
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

      def pw_hash(opts = {})
        password = opts.delete(:password) || ''
        salt = opts.delete(:salt) || ''
        iterations = opts.delete(:iterations) || 4096

        raise ArgumentError, 'too few iterations' unless iterations.to_i >= 1024
        raise ArgumentError, 'must include a password' if password.empty?
        raise ArgumentError, 'must includ a salt' if salt.empty?

        OpenSSL::PKCS5.pbkdf2_hmac(
          password, salt, iterations, 32, OpenSSL::Digest::SHA256.new
        ).unpack('H*')[0].force_encoding('ASCII-8bit')
      end

      def sanitized_name(name)
        name ||= ''
        # a-zA-Z0-9_-
        name.gsub(/[^a-zA-Z0-9_-]/, '')
      end

      def sanitized_key(key)
        key ||= ''
        key.gsub(/[^a-f0-9]/, '')
      end

      def val_if_int(raw)
        parsed = raw.to_i
        # maximum value that sqlite3 considers an integer: 2^63-1
        parsed = '' unless parsed < 9223372036854775808
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
end
