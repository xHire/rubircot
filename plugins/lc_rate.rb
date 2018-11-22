#####
## RubIRCot
###
#> plugin/lc_rate.rb
#~ Plugin that provides current exchange rate of Litecoin
####
# Author: xHire, 2017
# E-mail: xhire@mujmalysvet.cz
#####

require 'rubygems'
require 'json'
require 'open-uri'

class PluginLcRate
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'lc_rate'
    @cmd  = 'kurzltc'
    @help = 'get exchange rate of Litecoin'
  end

  def run channel, params = ''
  begin
    cache = '/tmp/rubircot/lc_rate/'
    ltc = {}
    threads = []

    # create the directory for cache if necessary
    system "mkdir -p #{cache}"
    Dir.chdir cache

    threads << Thread.start do
    begin
      # obtain BTC/LTC rate -- kraken
      ticker = open('https://api.kraken.com/0/public/Ticker?pair=XLTCXXBT').readline.strip
      ltc[:kraken_btc] = JSON.parse(ticker)['result']['XLTCXXBT']['c'][0].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, kraken doesn't respond."
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, kraken shouts HTTP error: #{err}"
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, kraken reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, kraken has some SSL difficulties"
    end
    ltc[:kraken_btc] ||= 0.0
    end

    # wait for all threads
    threads.each do |t|
      t.join
    end

    # compile all the data
    $bot.put "PRIVMSG #{channel} :BTC: " +
      "[Kraken] #{ltc[:kraken_btc]}"
  rescue Timeout::Error => e
    $bot.put "PRIVMSG #{channel} :Sorry, timeout :c("
    puts "[KURZ] Exception was raised: #{e.inspect}"
    puts e.backtrace.join("\n")
  rescue => e
    $bot.put "PRIVMSG #{channel} :Huh, something went wrong! =-O"
    puts "[KURZ] Exception was raised: #{e.inspect}"
    puts e.backtrace.join("\n")
  end
  end

  private
  def round num
    ((num.to_f * 100).round / 100.0).to_s.sub('.', ',')
  end
end
