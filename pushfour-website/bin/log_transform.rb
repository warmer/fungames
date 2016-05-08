#!/usr/bin/env ruby

require 'date'
require 'fileutils'
require 'json'

def parsed_access(log)
  info = []
  lines = File.read(log).split("\n")
  lines.each do |line|
    if line =~ /^(\d+\.\d+\.\d+\.\d+) - - \[([^\]]*)\] "(.*)" (\d+) (\d+|-) (\d+\.\d+)$/
      ip, time, request, code, size, load_time = [$1, $2, $3, $4, $5, $6]
      size = '0' if size == '-'
      datetime = DateTime.strptime(time, "%d/%b/%Y:%H:%M:%S %Z").iso8601
      verb = path = version = nil
      verb, path, version = [$1, $2, $3] if request =~ /^([^ ]+) (.*) (HTTP\/[A-Z0-9\.]+)$/
      data = {
        ip: ip, request: request, size: size,
        load_time: load_time, path: path, version: version
      }
      verb ||= 'unknown'
      key = "access_log/#{verb}/#{code}"
      info << {time: datetime, key: key, data: data}
    else
      puts "###### Line did not match :-( #{line}"
    end
  end
  info
end

def parsed_profile(log)
  info = []
  lines = File.read(log).split("\n")
  lines.each do |line|
    if line =~ /^([^ ]+) ([^ ]+) (.*) (\{.*\})$/
      time, method, request, profile = [$1, $2, $3, $4]
      profile = JSON.parse(profile)
      next if profile.empty?
      request_root = request.split('/')[1]
      key_base = "profiling/#{request_root}/#{method}"
      profile.each do |key, value|
        key = "#{key_base}/#{key}"
        info << {
          time: time, data: {count: value, request: request},
          key: key
        }
      end
    else
      puts "###### Line did not match :-( #{line}"
    end
  end
  info
end

# Process all logs within the working directory
# 1. Find all of the log files
# 2. Read and convert all lines of each file
# 3. Write the converted lines from each file to a "processed" directory
# 4. Delete each source file
if __FILE__ == $0
  root_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))
  log_dir = File.join(root_dir, 'log/')
  working_dir = File.join(log_dir, 'working')
  processed_dir = File.join(log_dir, 'processed')
  log_files = Dir.glob(File.join(log_dir, '*.log'))

  working_files = Dir.glob(File.join(working_dir, '*.log'))
  puts "Log files in working directory: #{working_files.join(', ')}"

  access_log_files = Dir.glob(File.join(working_dir, '*-access.log'))
  profile_log_files = Dir.glob(File.join(working_dir, '*-profile.log'))

  # reach each file and convert the data
  access_logs = access_log_files.map {|log| parsed_access(log) }
  access_logs.flatten!
  profile_logs = profile_log_files.map {|log| parsed_profile(log) }
  profile_logs.flatten!

  access = {numerics: %w(load_time size), points: access_logs}
  profile = {numerics: ['count'], points: profile_logs}

  # write the files to the processed dir
  FileUtils.mkdir_p(processed_dir)
  file_date = DateTime.now.new_offset(0).iso8601(9).split('+')[0].gsub(':', '')

  processed_access = File.join(processed_dir, "#{file_date}-access.json")
  processed_profile = File.join(processed_dir, "#{file_date}-profile.json")


  unless access_logs.empty?
    puts "Access log:\n#{processed_access}"
    File.write(processed_access, access.to_json)
    puts '...written'
  end
  FileUtils.rm(access_log_files)
  puts "Deleted:\n#{access_log_files.join("\n")}"

  unless profile_logs.empty?
    puts "\nProfile logs:\n#{processed_profile}"
    File.write(processed_profile, profile.to_json)
    puts '...written'
  end
  FileUtils.rm(profile_log_files)
  puts "Deleted:\n#{profile_log_files.join("\n")}"
end
