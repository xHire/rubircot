#####
## RubIRCot
###
#> plugin/bc_rate.rb
#~ Plugin that provides current exchange rate of Bitcoin
####
# Author: Michal Zima, 2011
# E-mail: xhire@mujmalysvet.cz
#####

require 'rubygems'
require 'active_support/json'
require 'csv'
require 'open-uri'

class PluginBcRate
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'bc_rate'
    @cmd  = 'kurz'
    @help = 'get exchange rate of Bitcoin; use currency token as an argument'
  end

  def run channel, params = ''
  begin
    cache = '/tmp/rubircot/bc_rate/'
    rate = { :czk => 1.0 }
    btc = {}

    # create the directory for cache if necessary
    system "mkdir -p #{cache}"
    Dir.chdir cache

    # get the currencies rates
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

    begin
      # obtain USD/BTC rate -- mtgox
      ticker = open("https://www.mtgox.com/code/ticker.php", "User-Agent" => "Mozilla/5.0 (Linux) RubIRCot/0.0.2")
      btc[:mtgox_usd] = ActiveSupport::JSON.decode(ticker.readline.strip)["ticker"]["last"].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, mtgox doesn't respond."
      btc[:mtgox_usd] = 0.0
    end

    begin
      # obtain USD/BTC rate -- tradehill
      ticker = open("https://api.tradehill.com/APIv1/USD/Ticker")
      btc[:th_usd] = ActiveSupport::JSON.decode(ticker.readline.strip)["ticker"]["last"].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, tradehill doesn't respond."
      btc[:th_usd] = 0.0
    end

    begin
      # obtain USD/BTC rate -- bitcoin7
      #ticker = open("https://www.bitcoin7.com/")
      #usd = ticker.readlines.detect {|l| l =~ /Last price:/ }.sub(/.*<strong>([^<]*).*/, '\1').to_f
      http = Net::HTTP.new('www.bitcoin7.com', Net::HTTP.https_default_port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      btc[:b7_usd] = http.start.get('/').body.match(/.*Last price: <strong>([^<]*).*/)[1].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, bitcoin7 doesn't respond."
      btc[:b7_usd] = 0.0
    end

    begin
      # obtain PLN/BTC rate -- bitomat
      ticker = open("https://bitomat.pl/code/data/ticker.php")
      btc[:bitomat_pln] = ActiveSupport::JSON.decode(ticker.readline.strip)["ticker"]["last"]
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, bitomat doesn't respond."
      btc[:bitomat_pln] = 0.0
    end

    # compile all the data
    params = 'usd' if params.nil? or params.empty?
    params.split.map {|c| c.downcase.to_sym }.uniq.each do |c|
      next unless rate.include?(c)
      $bot.put "PRIVMSG #{channel} :#{c.to_s.upcase}: [MtGox] #{round(btc[:mtgox_usd] * rate[:usd]/rate[c])} | [Th] #{round(btc[:th_usd] * rate[:usd]/rate[c])} | [B7] #{round(btc[:b7_usd] * rate[:usd]/rate[c])} | [Bitomat] #{round(btc[:bitomat_pln] * rate[:pln]/rate[c])}"
    end
  rescue => e
    $bot.put "PRIVMSG #{channel} :Huh, something went wrong! =-O"
    puts "[KURZ] Exception was raised: #{e.to_s}"
    puts e.backtrace.join("\n")
  end
  end

  private
  def round num
    ((num.to_f * 100).round / 100.0).to_s.sub('.', ',')
  end
end
