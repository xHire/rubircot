#####
## RubIRCot
###
#> plugin/bc_market.rb
#~ Plugin that provides further information about Bitcoin markets
####
# Author: Michal Zima, 2011
# E-mail: xhire@mujmalysvet.cz
#####

require 'rubygems'
require 'active_support/json'
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
      csv = CSV::Reader.parse(raw, '|')
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
      # obtain mtgox info
      ticker = open("https://www.mtgox.com/code/ticker.php", "User-Agent" => "Mozilla/5.0 (Linux) RubIRCot/#{$version}").readline.strip
      buy[:mtgox] = ActiveSupport::JSON.decode(ticker)["ticker"]["buy"].to_f
      sell[:mtgox] = ActiveSupport::JSON.decode(ticker)["ticker"]["sell"].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, mtgox doesn't respond."
      buy[:mtgox] = 0.0
      sell[:mtgox] = 0.0
    end
    end

    threads << Thread.start do
    begin
      # obtain tradehill info
      ticker = open("https://api.tradehill.com/APIv1/USD/Ticker").readline.strip
      buy[:th] = ActiveSupport::JSON.decode(ticker)["ticker"]["buy"].to_f
      sell[:th] = ActiveSupport::JSON.decode(ticker)["ticker"]["sell"].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, tradehill doesn't respond."
      buy[:th] = 0.0
      sell[:th] = 0.0
    end
    end

    threads << Thread.start do
    begin
      # obtain bitomat info
      ticker = open("https://bitomat.pl/code/data/ticker.php").readline.strip
      buy[:bitomat] = ActiveSupport::JSON.decode(ticker)["ticker"]["buy"].to_f * rate[:pln] / rate[:usd]
      sell[:bitomat] = ActiveSupport::JSON.decode(ticker)["ticker"]["sell"].to_f * rate[:pln] / rate[:usd]
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, bitomat doesn't respond."
      buy[:bitomat] = 0.0
      sell[:bitomat] = 0.0
    end
    end

    # wait for all threads
    threads.each do |t|
      t.join
    end

    # compile all the data
    $bot.put "PRIVMSG #{channel} :buy/sell: [MtGox] #{round(buy[:mtgox])}/#{round(sell[:mtgox])} | [Th] #{round(buy[:th])}/#{round(sell[:th])} | [Bitomat] #{round(buy[:bitomat])}/#{round(sell[:bitomat])}"
  rescue => e
    $bot.put "PRIVMSG #{channel} :Huh, something went wrong! =-O"
    puts "[TRH] Exception was raised: #{e.to_s}"
    puts e.backtrace.join("\n")
  end
  end

  private
  def round num
    ((num.to_f * 100).round / 100.0).to_s.sub('.', ',')
  end
end