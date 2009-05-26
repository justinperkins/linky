#!/usr/bin/env ruby
require 'rubygems'
require 'net/ssh'
require 'net/sftp'
require 'sha1'
class LinkyWorker

  CONFIG = './config.yml'
  
  attr_reader :config, :data_file, :uploader, :remote, :local

  def initialize(config = nil)
    @config = File.open(config || CONFIG) { |f| YAML::load(f) }
    @config = @config['env'] if @config && @config['env']

    # convert self-referencing keys to their respective values
    @config.each { |k,v| @config[k] = @config[v.to_s] if v.is_a?(Symbol) }

    @local_data_file = File.join(@config['local_base'], 'linky.yml')
    @remote_data_file = File.join(@config['remote_base'], 'linky.yml')
    Net::SFTP.start(@config['host'], @config['user']) do |sftp|
      @uploader = sftp
      yield self
      @uploader = nil
    end
  end
  
  def fetch_remote
    @remote = @uploader.download!(@remote_data_file) rescue nil
    @local = YAML::load(@remote)
    @local
  end
  
  def update_remote_from_local(local = nil)
    # allow a passed in file to override the config file that is initialized at startup
    @local_data_file = local if local
    puts "updating remote (#{ @remote_data_file }) with local file (#{ @local_data_file })"
    puts('no data file bud, at least put it in your config if you want this to work') and return unless @local_data_file
    @uploader.upload!(@local_data_file, @remote_data_file)
    puts 'all done'
  end
  
  def setup
    puts 'setting up your linky'
    puts 'title:'
    title = STDIN.gets.strip
    puts 'description:'
    description = STDIN.gets.strip
    puts 'comma separated fields (link, background_image and discovery_date are magic, you should use them)'
    fields = STDIN.gets.strip.split(',').collect { |f| f.strip }
    @local = {"info" => {"title" => title, "description" => description}, "fields" => fields}
    send_local_data_to_remote
  end
  
  def update_title_and_description
    puts 'updating your linky'
    fetch_remote
    puts "the current title is #{ @local['info']['title'] }, what is the new title?"
    title = STDIN.gets.strip
    puts "the current description is #{ @local['info']['description'] }, what is the new description?"
    description = STDIN.gets.strip
    @local['info'] = {'title' => title, 'description' => description}

    # set up the secret key if we don't have one already
    @local['info']['secret_key'] = Digest::SHA1.hexdigest(Time.now.to_f.to_s) unless @local['info']['secret_key']
    send_local_data_to_remote
  end
  
  def prompt_for_entry_and_send_to_remote
    puts "downloading linky file from server at #{ @remote_data_file }"
    
    if fetch_remote
      self.add_entry(input_for_item(@local['fields']))
      send_local_data_to_remote
    else
      puts 'file not found, would you like to set one up?'
      if STDIN.gets.strip =~ /y[es]?/
        setup
        self.add_entry(input_for_item(@local['fields']))
        send_local_data_to_remote
      end
    end
  end
  
  def add_entry(entry)
    @local['items'] ||= {}
    @local['items']["item#{ @local['items'].keys.size + 1 }"] = entry
  end
  
  def send_local_data_to_remote(local = nil)
    local ||= @local
    puts 'updating file on linky server from in-memory data'
    local_linky = File.join(@config['local_base'], 'linky.yml')
    File.open(local_linky, 'w+') { |f| f.write(local.to_yaml) }
    update_remote_from_local(local_linky)
  end

  private
  def input_for_item(fields)
    puts "adding a new item to your linky"
    fields.inject({}) do |memo, item|
      puts "enter a value for the #{ item } (#{ item == 'discovery_date' ? 'leave blank for today' : 'or enter to leave blank' })"
      memo[item] = STDIN.gets.strip
      if memo[item].empty? && item == 'discovery_date'
        memo[item] = "#{ Time.now.year }, #{ Time.now.month }, #{ Time.now.day }"
      end
      memo
    end
  end
end

if __FILE__ == $0
  LinkyWorker.new do |linky|
    switch = ARGV.first
    case switch
    when '--help', '-?'
      puts 'Help info for linky worker script'
      puts '-a'
      puts "\tdefault behavior when no arugments provided, adds a new item to your remote linky file and creates one if none is found\n"
      puts '-d [optional local file path]'
      puts "\tupdate your remote linky file with whatever is stored in the local file defined in your config or provided as an argument\n"
      puts '-s'
      puts "\tsetup your linky file on the remote server, with whatever fields you want\n"
      puts '-u'
      puts "\tupdate the linky title and description\n"
      puts '--help, -?'
      puts "\tthis help"
    when '-d'
      if linky.data_file || ARGV[1]
        linky.update_remote_from_local(ARGV[1])
      else
        puts 'need data file, try ./linky.rb -d path/to/linky.yml and make sure the file exists'
      end
    when '-s'
      linky.setup
    when '-u'
      linky.update_title_and_description
    when '-a', nil
      linky.prompt_for_entry_and_send_to_remote
    else
      puts 'unknown option, use --help for known options'
    end
  end
end