#####
## RubIRCot
###
#> plugin/bc_market.rb
#~ Plugin that provides further information about Bitcoin markets
####
# Author: Michal Zima, 2013
# E-mail: xhire@mujmalysvet.cz
#####

require 'rubygems'
require 'json'
require 'csv'
require 'open-uri'

class PluginBcMarket
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'bc_market'
    @cmd  = 'trh'
    @help = 'get extra info about Bitcoin markets'
  end

  def run channel, params = ''
  begin
    cache = '/tmp/rubircot/bc_rate/'
    rate = { :czk => 1.0 }
    buy = {}
    sell = {}
    threads = []

    # create the directory for cache if necessary
    system "mkdir -p #{cache}"
    Dir.chdir cache

    # get the currencies rates
    threads << Thread.start do
    now = Time.now
    if File.exist?('cnb') and File.stat('cnb').mtime >= (now >= Time.local(now.year, now.month, now.day, 15) ? now : Time.local(now.year, now.month, now.day, 15) - 86400)
      rate = Marshal.load(File.open('cnb'))
    else
      raw = open("http://www.cnb.cz/cs/financni_trhy/devizovy_trh/kurzy_devizoveho_trhu/denni_kurz.txt")
      if RUBY_VERSION >= '1.9'
        csv = CSV.parse(raw, :col_sep => '|')
      else
        csv = CSV::Reader.parse(raw, '|')
      end
      2.times do
        csv.shift
      end
      csv.each do |row|
        rate[row[3].downcase.to_sym] = row[4].sub(',', '.').to_f
      end
      File.open('cnb', 'w') do |f|
        f.puts Marshal.dump(rate)
      end
    end
    end

    threads << Thread.start do
    begin
      # obtain bitstamp info
      ticker = open('https://www.bitstamp.net/api/ticker/').readline.strip
      buy[:bs] = JSON.parse(ticker)['bid'].to_f
      sell[:bs] = JSON.parse(ticker)['ask'].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp doesn't respond."
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp shouts HTTP error: #{err}"
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp has some SSL difficulties"
    end
    buy[:bs]  ||= 0.0
    sell[:bs] ||= 0.0
    end

=begin
    threads << Thread.start do
    begin
      # obtain btc-e info
      ticker = open('https://btc-e.com/api/2/btc_usd/ticker').readline.strip
      buy[:btce] = JSON.parse(ticker)['ticker']['sell']
      sell[:btce] = JSON.parse(ticker)['ticker']['buy']
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e doesn't respond."
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e shouts HTTP error: #{err}"
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e has some SSL difficulties"
    end
    buy[:btce]  ||= 0.0
    sell[:btce] ||= 0.0
    end
=end

    # wait for all threads
    threads.each do |t|
      t.join
    end

    # compile all the data
    $bot.put "PRIVMSG #{channel} :buy/sell: " +
      "[Bitstamp] #{round(buy[:bs])}/#{round(sell[:bs])} | " +
      ''#"[BTC-e] #{round(buy[:btce])}/#{round(sell[:btce])}"
  rescue Timeout::Error => e
    $bot.put "PRIVMSG #{channel} :Sorry, timeout :c("
    puts "[TRH] Exception was raised: #{e.inspect}"
    puts e.backtrace.join("\n")
  rescue => e
    $bot.put "PRIVMSG #{channel} :Huh, something went wrong! =-O"
    puts "[TRH] Exception was raised: #{e.inspect}"
    puts e.backtrace.join("\n")
  end
  end

  private
  def round num
    ((num.to_f * 100).round / 100.0).to_s.sub('.', ',')
  end
end
