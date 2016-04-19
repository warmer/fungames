require 'timeout'
require 'fileutils'
require 'net/http'
require 'sqlite3'
require_relative '../p4web.rb'
require_relative '../lib/database.rb'

@@harness

TEST_DB_PATH = File.expand_path(File.join(__FILE__, '../temp_database.db'))

module Pushfour
  module Website
    class Harness
      attr_reader :mock_db, :run_web, :web_port
      attr_reader :web_err, :web_pid

      def initialize(opts = {})
        @mock_db = opts[:mock_db]
        @run_web = opts[:run_web]
        @web_port = opts[:web_port] || 9876
      end

      def create_database
        return unless @mock_db
        cleanup
        Database.db_file(TEST_DB_PATH)
        Database.create(silent: true)
      end

      def run_webserver
        return unless @run_web
        @web_err = StringIO.new
        @web_pid = fork do
          ENV['PUSHFOUR_DB_FILE'] = TEST_DB_PATH if @mock_db
          $stderr = @web_err
          Rack::Handler::WEBrick.run(PushfourWebsite, {Port: @web_port}) do |s|
            [:INT, :TERM].each {|sig| trap(sig) { s.stop } }
          end
        end
      end

      def cleanup
        FileUtils.rm_f(TEST_DB_PATH)
      end

      def get(path)
        uri = URI("http://localhost:#{@web_port}/#{path}")
        Net::HTTP.get(uri)
      end

      def post(path, params)
        uri = URI("http://localhost:#{@web_port}/#{path}")
        Net::HTTP.post_form(uri, params)
      end

      def self.run_test(opts = {}, &blk)
        begin
          Harness.run_test_throw(opts, &blk)
        rescue RuntimeError => e
          puts "*** #{$!}"
          puts e.backtrace
          Kernel.exit 1
        rescue Timeout::Error
          puts "!!! test timed out"
          Kernel.exit 1
        ensure
          Process.kill('INT', @@harness.web_pid) if @@harness.web_pid
        end
      end

      def self.run_test_throw(opts = {}, &blk)
        harness = Harness.new(opts)
        @@harness = harness
        harness.create_database
        harness.run_webserver
        maxtime = opts[:maxtime] || 10

        Timeout.timeout(maxtime) do
          if block_given?
            harness.instance_exec(&blk)
            harness.cleanup
          end
        end
      end

    end
  end
end
