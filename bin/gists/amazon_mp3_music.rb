require 'hpricot'
require 'open-uri'

class AmazonMp3Music
  ASSOCIATE_ID = 'enjoybeing-20'
  AMAZON_INJECTED_STRINGS = [' (Amazon Exclusive)', ' [Explicit]']

  attr_accessor :asin, :artist, :album, :album_image, :referral_url, :processed
  def initialize(url)
    @url = url
    @document = Hpricot(open(@url))
    @asin = (@document/'#ASIN').first[:value]

    if (@document/'#handleBuy/div.buying/b.sans').size == 0
      puts('not the type of page I expected, are you sure that is an Amazon MP3 Album page?')
      return
    end

    @album = trim_the_bullshit((@document/'#handleBuy/div.buying/b.sans').first.inner_html)
    @artist = (@document/'#handleBuy/div.buying/span.sans/b/a').inner_html
    @album_image = (@document/'#prodImage').first[:src]
    @referral_url = build_referral_url
    @processed = true
  end
  
  private
  def build_referral_url
    matches = @url.match(/\/#{ @asin }\/(.*)$/)
    matches ? @url.gsub(matches[1], "?tag=#{ ASSOCIATE_ID }") : @url
  end
  
  def trim_the_bullshit(string)
    AMAZON_INJECTED_STRINGS.each { |s| string.gsub!(s, '') }
    string
  end
end