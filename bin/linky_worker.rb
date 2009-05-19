#!/usr/bin/env ruby
require 'rubygems'
require 'net/ssh'
require 'net/sftp'

class LinkyWorker

  CONFIG = './config.yml'
  
  attr_reader :config, :data_file

  def initialize
    @config = File.open(CONFIG) { |f| YAML::load(f) }
    @config = @config['env'] if @config
    @data_file = @config['local']
    Net::SFTP.start(@config['host'], @config['user']) do |sftp|
      @uploader = sftp
      yield self
      @uploader = nil
    end
  end
  
  def fetch_remote
    @remote = @uploader.download!(@config['remote']) rescue nil
    @remote
  end
  
  def update_remote_from_local(local = nil)
    # allow a passed in file to override the config file that is initialized at startup
    puts "updating remote (#{ @config['remote'] }) with local file (#{ @data_file })"
    @data_file = local if local
    puts('no data file bud, at least put it in your config if you want this to work') and return unless @data_file
    @uploader.upload!(@data_file, @config['remote'])
    puts 'all done'
  end
  
  def setup
    puts 'setting up your linky'
    puts 'title:'
    title = STDIN.gets.strip
    puts 'description:'
    description = STDIN.gets.strip
    puts 'comma separated fields (link, background_image and discovery_date are magic, you should use them)'
    fields = STDIN.gets.strip.split(',')
    @local = {"info" => {"title" => title, "description" => description}, "items" => {"item1" => fields.inject({}){ |m, i| m[i] = ''; m; }}}
    send_local_data_to_remote
  end
  
  def add_entry_to_remote
    puts "downloading linky file from server at #{ @config['remote'] }"
    
    if fetch_remote
      @local = YAML::load(@remote)
      items = @local['items']
      first_item = items[items.keys.first]
      @local['items']["item#{ items.keys.size + 1 }"] = input_for_item(first_item.keys)
      send_local_data_to_remote
    else
      puts 'file not found, would you like to set one up?'
      if STDIN.gets.strip =~ /y[es]?/
        setup
        @local['items']['item1'] = input_for_item(@local['items']['item1'].keys)
        send_local_data_to_remote
      end
    end
  end
  
  private
  def input_for_item(fields)
    puts "adding a new item to your linky"
    fields.inject({}) do |memo, item|
      item.strip!
      puts "enter a value for the #{ item } (#{ item == 'discovery_date' ? 'leave blank for today' : 'or enter to leave blank' })"
      memo[item] = STDIN.gets.strip
      if memo[item].empty? && item == 'discovery_date'
        memo[item] = "#{ Time.now.year }, #{ Time.now.month }, #{ Time.now.day }"
      end
      memo
    end
  end

  def send_local_data_to_remote
    puts 'updating file on linky server from in-memory data'
    # net/sftp does not support uploading a file if it doesn't exist locally, so we must create a tmp file
    File.open(@config['temp'], 'w+') { |f| f.write(@local.to_yaml) }
    update_remote_from_local(@config['temp'])
    File.delete(@config['temp'])
  end
end

if __FILE__ == $0
  LinkyWorker.new do |linky|
    switch = ARGV.first
    case switch
    when '-d'
      if linky.data_file || ARGV[1]
        linky.update_remote_from_local
      else
        puts 'need data file, try ./linky.rb -d path/to/linky.yml'
      end
    when '-s'
      linky.setup
    when '-a', nil
      linky.add_entry_to_remote
    end
  end
end