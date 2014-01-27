#####
## RubIRCot
###
#> plugin/bc_rate.rb
#~ Plugin that provides current exchange rate of Bitcoin
####
# Author: Michal Zima, 2013
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
    2.times do
    begin
      # obtain USD/BTC rate -- mtgox
      ticker = open('https://data.mtgox.com/api/1/BTCUSD/ticker', 'User-Agent' => "Mozilla/5.0 (Linux) RubIRCot/#{$version}")
      btc[:mtgox_usd] = ActiveSupport::JSON.decode(ticker.readline.strip)['return']['last_local']['value'].to_f
      break
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, mtgox doesn't respond."
      break
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, mtgox shouts HTTP error: #{err}"
      break
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, mtgox reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, mtgox has some SSL difficulties"
      break
    end
    end
    btc[:mtgox_usd] ||= 0.0
    end

    threads << Thread.start do
    begin
      # obtain USD/BTC rate -- bitstamp
      ticker = open('https://www.bitstamp.net/api/ticker/')
      btc[:bs_usd] = ActiveSupport::JSON.decode(ticker.readline.strip)['last'].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp doesn't respond."
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp shouts HTTP error: #{err}"
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, bitstamp has some SSL difficulties"
    end
    btc[:bs_usd] ||= 0.0
    end

    threads << Thread.start do
    begin
      # obtain USD/BTC rate -- btc-e
      ticker = open('https://btc-e.com/api/2/btc_usd/ticker')
      btc[:btce_usd] = ActiveSupport::JSON.decode(ticker.readline.strip)['ticker']['last']
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e doesn't respond."
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e shouts HTTP error: #{err}"
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, btc-e has some SSL difficulties"
    end
    btc[:btce_usd] ||= 0.0
    end

    threads << Thread.start do
    begin
      # obtain CNY/BTC rate -- btcchina
      ticker = open('https://vip.btcchina.com/bc/ticker')
      btc[:btcchina_cny] = ActiveSupport::JSON.decode(ticker.readline.strip)['ticker']['last'].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, btcchina doesn't respond."
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, btcchina shouts HTTP error: #{err}"
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, btcchina reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, btcchina has some SSL difficulties"
    end
    btc[:btcchina_cny] ||= 0.0
    end

    # wait for all threads
    threads.each do |t|
      t.join
    end

    # compile all the data
    any = false
    params.split.map {|c| c.downcase.to_sym }.uniq.each do |c|
      rate.include?(c) ? any = true : next
      $bot.put "PRIVMSG #{channel} :#{c.to_s.upcase}: " +
        "[MtGox] #{round(btc[:mtgox_usd] * rate[:usd] / rate[c])} | " +
        "[Bitstamp] #{round(btc[:bs_usd] * rate[:usd] / rate[c])} | " +
        "[BTC-e] #{round(btc[:btce_usd] * rate[:usd] / rate[c])} | " +
        "[BTC China] #{round(btc[:btcchina_cny] * rate[:cny] / rate[c])}"
    end
    unless any
      $bot.put "PRIVMSG #{channel} :USD/CZK: " +
        "[MtGox] #{round(btc[:mtgox_usd])}/#{round(btc[:mtgox_usd] * rate[:usd])} | " +
        "[Bitstamp] #{round(btc[:bs_usd])}/#{round(btc[:bs_usd] * rate[:usd])} | " +
        "[BTC-e] #{round(btc[:btce_usd])}/#{round(btc[:btce_usd] * rate[:usd])} | " +
        "[BTC China] #{round(btc[:btcchina_cny] * rate[:cny] / rate[:usd])}/#{round(btc[:btcchina_cny] * rate[:cny])}"
    end
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
