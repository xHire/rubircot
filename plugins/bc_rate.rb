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
require 'json'
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
    begin
      # obtain USD/BTC rate -- bitstamp
      ticker = open('https://www.bitstamp.net/api/ticker/')
      btc[:bs_usd] = JSON.parse(ticker.readline.strip)['last'].to_f
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

=begin
    threads << Thread.start do
    begin
      # obtain USD/BTC rate -- btc-e
      ticker = open('https://btc-e.com/api/2/btc_usd/ticker')
      btc[:btce_usd] = JSON.parse(ticker.readline.strip)['ticker']['last']
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
=end

    threads << Thread.start do
    begin
      # obtain EUR/BTC rate -- kraken
      ticker = open('https://api.kraken.com/0/public/Ticker?pair=XXBTZEUR').readline.strip
      btc[:kraken_eur] = JSON.parse(ticker)['result']['XXBTZEUR']['c'][0].to_f
    rescue Errno::ETIMEDOUT
      $bot.put "PRIVMSG #{channel} :Sorry, kraken doesn't respond."
    rescue OpenURI::HTTPError => err
      $bot.put "PRIVMSG #{channel} :Sorry, kraken shouts HTTP error: #{err}"
    rescue Errno::ECONNRESET
      $bot.put "PRIVMSG #{channel} :Sorry, kraken reset the connection"
    rescue OpenSSL::SSL::SSLError
      $bot.put "PRIVMSG #{channel} :Sorry, kraken has some SSL difficulties"
    end
    btc[:kraken_eur] ||= 0.0
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
        "[Bitstamp] #{round(btc[:bs_usd] * rate[:usd] / rate[c])} | " +
        #"[BTC-e] #{round(btc[:btce_usd] * rate[:usd] / rate[c])} | " +
        "[Kraken] #{round(btc[:kraken_eur] * rate[:eur] / rate[c])}"
    end
    unless any
      $bot.put "PRIVMSG #{channel} :USD/CZK: " +
        "[Bitstamp] #{round(btc[:bs_usd])}/#{round(btc[:bs_usd] * rate[:usd])} | " +
        #"[BTC-e] #{round(btc[:btce_usd])}/#{round(btc[:btce_usd] * rate[:usd])} | " +
        "[Kraken] #{round(btc[:kraken_eur] * rate[:eur] / rate[:usd])}/#{round(btc[:kraken_eur] * rate[:eur])}"
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
