# frozen_string_literal: true

Bundler.require
require 'open-uri'

Dotenv.load
ACCESS_TOKEN = ENV['ACCESS_TOKEN']
DOWNLOAD_DIR = (ENV['DOWNLOAD_DIR'] || 'download').freeze
WAIT_SECONDS_ON_ERROR = ENV['WAIT_SECONDS_ON_ERROR'] || 10
AUTHORIZATION = { 'Authorization' => "Bearer #{ACCESS_TOKEN}" }.freeze
COUNT = 1000
client = Slack::Web::Client.new token: ACCESS_TOKEN

unless Dir.exist? DOWNLOAD_DIR
  puts "Create #{DOWNLOAD_DIR} directory."
  Dir.mkdir DOWNLOAD_DIR
end

page = 1

loop do
  files_list = client.files_list count: COUNT, page: page
  pages = files_list.paging.pages

  files_list.files.each do |file|
    original_filename = file.name
    download_filename = original_filename
    filename_count = 0

    if file.url_private_download.nil?
      puts "Skip #{original_filename} because it can't be download."
    else
      loop do
        puts "#{download_filename} exists."
        filename_count += 1

        download_filename =
          if original_filename.include? '.'
            original_filename.sub('.', " #{filename_count}.")
          else
            "#{original_filename} #{filename_count}"
          end

        break unless File.exist? "#{DOWNLOAD_DIR}/#{download_filename}"
      end

      puts "Download #{download_filename}"

      begin
        File.open("#{DOWNLOAD_DIR}/#{download_filename.gsub('/', '_')}", 'wb') do |output|
          output.write(URI.parse(file.url_private_download).open(AUTHORIZATION).read)
        end
      rescue StandardError => e
        puts "An error has occurred: #{e}"
        puts "Wait #{WAIT_SECONDS_ON_ERROR} seconds due to an error."
        sleep WAIT_SECONDS_ON_ERROR
        redo
      end
    end
  end

  page += 1
  break if page > pages
end

puts 'All processing is complete.'
