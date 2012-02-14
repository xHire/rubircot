#####
## RubIRCot
###
#> plugin/me.rb
#~ Plugin that tells who I am
####
# Author: Michal Zima, 2011
# E-mail: xhire@mujmalysvet.cz
#####

class PluginMe
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'me'
    @cmd  = 'me'
    @help = 'tells who I am'
  end

  def run channel, params = ''
    $bot.put "PRIVMSG #{channel} :\001ACTION is RubIRCot v#{$version} -- friendly IRC bot written in Ruby. Please #{$bot.config[:cmdchar]}donate\001"
  end
end
