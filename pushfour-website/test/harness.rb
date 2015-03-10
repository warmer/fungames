require 'sqlite3'
require 'timeout'
require 'fileutils'
require_relative '../lib/database.rb'

@@harness

TEST_DB_PATH = File.expand_path(File.join(__FILE__, '../temp_database.db'))

class Harness
  def initialize(opts = {})
    @mock_db = opts[:mock_db]

    create_database if @mock_db
  end

  def create_database
    Pushfour::Database.db_file(TEST_DB_PATH)
    Pushfour::Database.create(silent: true)
  end

  def cleanup
    FileUtils.rm_f(TEST_DB_PATH)
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
    end
  end

  def self.run_test_throw(opts = {}, &blk)
    harness = Harness.new(opts)
    @@harness = harness
    maxtime = opts[:maxtime] || 10

    Timeout.timeout(maxtime) do
      if block_given?
        harness.instance_exec(&blk)
        harness.cleanup
      end
    end
  end

end
