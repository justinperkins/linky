#!/usr/bin/env ruby
require 'linky_worker'
require 'gists/amazon_mp3_music'
require 'gists/image_resizer'

class AmazonMusicWorker
  include ImageResizer
  
  def initialize
    puts 'starting up the scraper'
    LinkyWorker.new do |linky|
      @linky = linky
      puts 'fetching the data file first'
      @linky.fetch_remote
      yield self
      puts 'sending the data file back up'
      @linky.send_local_data_to_remote(@data)
    end
  end
  
  def parse_url(url)
    info = AmazonMp3Music.new(url)
    return unless info.processed
    linky_data = {'artist' => info.artist, 'album' => info.album, 'link' => info.referral_url}
    process_image(info.album_image, linky_data)
    @linky.add_entry(linky_data)
  end
  
  def process_image(image_url, data)
    image_name = to_filename("#{ data['artist'] }_#{ data['album'] }.jpg")
    local_file = File.join(@linky.config['local_base'], 'imagery', image_name)
    remote_file = File.join(@linky.config['remote_base'], 'imagery', image_name)
    File.open(local_file, 'w+') do |f|
      f.write(open(image_url).readlines)
    end
    resize(local_file)
    @linky.uploader.upload!(local_file, remote_file)
    data['background_image'] = "http://#{ File.join(@linky.config['website'], 'imagery', image_name) }"
  end
  
  private
  def to_filename(string)
    string.gsub(' ', '-')
  end
end

if __FILE__ == $0
  AmazonMusicWorker.new do |scraper|
    if ARGV.first == '-url'
      puts('expected url') and break unless ARGV[1]
      scraper.gather_from_url(ARGV[1])
    else
      puts 'input a url to scrape or just hit enter to stop (needs to be an Amazon MP3 Album page)'
      while !(url = STDIN.gets.strip).empty?
        scraper.parse_url(url) unless url.empty?
        puts 'input a url to scrape or just hit enter to stop'
      end
    end
  end
end