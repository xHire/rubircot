#!/usr/bin/env ruby
#####
## RubIRCot
###
#> rubircot.rb
#~ This is core program of RubIRCot
####
# Author: Michal Zima, 2013
# E-mail: xhire@tuxportal.cz
#####
$version = '0.0.4'
#####

### Include libraries
require 'yaml'
require 'timeout'
require 'socket'
require 'fileutils'
require './lib/irc'
require './lib/string'

### Create an instance of main IRCbot class
$bot = RubIRCot.new

### Handle some signals
def exit
  puts "RubIRCot is terminating..."
  $bot.quit
  Process.exit
end
# TERM -KILL- QUIT INT
trap "INT"  do; exit; end
trap "TERM" do; exit; end
trap "QUIT" do; exit; end

### Set up output
$stdout.sync = true
$stderr.sync = true

### Say "hello" to output
puts "RubIRCot v#{$version} started"

### Load plugins
$plugins = {}
Dir.foreach 'plugins' do |plugin|
  next unless plugin =~ /^.*\.rb$/
  require './plugins/'+ plugin
  plname = plugin.sub /\.rb/, ''
  plugin = Object.module_eval("::Plugin#{plname.camelize}", __FILE__, __LINE__).new
  $plugins[plugin.cmd] = plugin
end

### Run the bot
begin
  # connect and join
  $bot.connect
  # listen for all messages and react to them
  loop do
    begin
      timeout 300 do
        $bot.get
      end
    rescue Timeout::Error
      timeout 5 do
        $bot.ping
      end
    end
  end
rescue Timeout::Error, Errno::ETIMEDOUT
  puts "Connection timeouted. Reconnecting..."
  $bot.quit
  retry
rescue Errno::ECONNRESET
  puts "Connection reset by peer. Reconnecting..."
  $bot.quit
  retry
rescue EOFError, Errno::EPIPE
  puts "Error when reading from socket. Reconnecting..."
  $bot.quit
  retry
rescue SocketError
  puts 'Problem with socket. Waiting 2 minutes before reconnecting...'
  $bot.quit
  sleep 120
  retry
end
