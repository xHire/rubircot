#####
## RubIRCot
###
#> plugin/bc_rate2diff.rb
#~ Plugin that calculates difficulty of Bitcoin network for given hashrate
####
# Author: Michal Zima, 2013
# E-mail: xhire@mujmalysvet.cz
#####

require 'bigdecimal'

class PluginBcRate2diff
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'bc_rate2diff'
    @cmd  = 'r2d'
    @help = 'calculate difficulty of Bitcoin network for given hashrate in Thps'
  end

  def run channel, params = ''
    hashrate = BigDecimal.new(params)
    if hashrate.zero?
      $bot.put "PRIVMSG #{channel} :Error! No hashrate number given!"
    else
      diff = (hashrate * 1000_000_000_000 * 600) / 2**32
      $bot.put "PRIVMSG #{channel} :" + diff.round(6).to_s('F')
    end
  end
end
