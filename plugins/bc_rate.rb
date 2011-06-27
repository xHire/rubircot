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

class PluginKurz
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'bc_rate'
    @cmd  = 'kurz'
    @help = 'get exchange rate of Bitcoin'
  end

  def run channel, params = ''
  begin
    cache = '/tmp/rubircot/bc_rate/'
    rate = {}

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
      # obtain USD/BTC rate
      ticker = open("https://www.mtgox.com/code/ticker.php", "User-Agent" => "Mozilla/5.0 (Linux) RubIRCot/0.0.2")
      usd = ActiveSupport::JSON.decode(ticker.readline.strip)["ticker"]["last"].to_f

      # send the data
      $bot.put "PRIVMSG #{channel} :[MT] 1 BTC = #{round(usd)} USD | #{round(usd * rate[:usd]/rate[:eur])} EUR | #{round(usd * rate[:usd])} CZK"
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :[MT] Sorry, mtgox doesn't respond."
    end

    begin
      # obtain USD/BTC rate
      ticker = open("https://api.tradehill.com/APIv1/USD/Ticker")
      usd = ActiveSupport::JSON.decode(ticker.readline.strip)["ticker"]["last"].to_f

      # send the data
      $bot.put "PRIVMSG #{channel} :[TH] 1 BTC = #{round(usd)} USD | #{round(usd * rate[:usd]/rate[:eur])} EUR | #{round(usd * rate[:usd])} CZK | #{round(usd * rate[:usd]/rate[:pln])} PLN"
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :[TH] Sorry, tradehill doesn't respond."
    end

    begin
      # obtain USD/BTC rate
      #ticker = open("https://www.bitcoin7.com/")
      #usd = ticker.readlines.detect {|l| l =~ /Last price:/ }.sub(/.*<strong>([^<]*).*/, '\1').to_f
      http = Net::HTTP.new('www.bitcoin7.com', Net::HTTP.https_default_port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      usd = http.start.get('/').body.match(/.*Last price: <strong>([^<]*).*/)[1].to_f

      # send the data
      $bot.put "PRIVMSG #{channel} :[B7] 1 BTC = #{round(usd)} USD | #{round(usd * rate[:usd]/rate[:eur])} EUR | #{round(usd * rate[:usd])} CZK | #{round(usd * rate[:usd]/rate[:pln])} PLN"
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :[B7] Sorry, tradehill doesn't respond."
    end

    begin
      # obtain PLN/BTC rate
      ticker = open("https://bitomat.pl/code/data/ticker.php")
      pln = ActiveSupport::JSON.decode(ticker.readline.strip)["ticker"]["last"]

      # send the data
      $bot.put "PRIVMSG #{channel} :[PL] 1 BTC = #{round(pln * rate[:pln]/rate[:usd])} USD | #{round(pln * rate[:pln]/rate[:eur])} EUR | #{round(pln * rate[:pln])} CZK | #{round(pln)} PLN"
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :[PL] Sorry, bitomat doesn't respond."
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
