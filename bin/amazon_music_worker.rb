#!/usr/bin/env ruby
require 'linky_worker'
require 'iconv' # for working with I18N strings
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
    image_name = parameterize("#{ data['artist'] }_#{ data['album'] }.jpg")
    local_file = File.join(@linky.config['local_base'], 'public', 'imagery', image_name)
    remote_file = File.join(@linky.config['remote_base'], 'public', 'imagery', image_name)
    File.open(local_file, 'w+') do |f|
      f.write(open(image_url).readlines)
    end
    resize(local_file)
    @linky.uploader.upload!(local_file, remote_file)
    data['background_image'] = "http://#{ File.join(@linky.config['website'], 'imagery', image_name) }"
  end
  
  private
  def parameterize(string, sep = '-')
    # replace accented chars with ther ascii equivalents
    parameterized_string = transliterate(string)
    # Turn unwanted chars into the seperator
    parameterized_string.gsub!(/[^a-z0-9\-_\+]+/i, sep)
    unless sep.empty? || sep.nil?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/i, '')
    end
    parameterized_string.downcase
  end

  def transliterate(string)
    Iconv.iconv('ascii//ignore//translit', 'utf-8', string).to_s
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