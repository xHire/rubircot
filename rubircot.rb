#!/usr/bin/env ruby
#####
## RubIRCot
###
#> rubircot.rb
#~ This is core program of RubIRCot
####
# Author: Michal Zima, 2008
# E-mail: xhire@tuxportal.cz
#####
$version = '0.0.3'
#####

### Include libraries
require 'yaml'
require 'socket'
require 'fileutils'
require 'lib/irc'
require 'rubygems'
require 'active_support/inflector'

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

### Say "hello" to output
puts "RubIRCot v#{$version} started"

### Load plugins
$plugins = {}
Dir.foreach 'plugins' do |plugin|
  next unless plugin =~ /^.*\.rb$/
  require 'plugins/'+ plugin
  plname = plugin.sub /\.rb/, ''
  plugin = Object.module_eval("::Plugin#{plname.camelize}", __FILE__, __LINE__).new
  $plugins[plugin.cmd] = plugin
end

### Run the bot
# connect and join
$bot.connect
# listen for all messages and react to them
$bot.get while(1)
