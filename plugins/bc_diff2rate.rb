#####
## RubIRCot
###
#> plugin/bc_diff2rate.rb
#~ Plugin that calculates hashrate of Bitcoin network for given difficulty
####
# Author: Michal Zima, 2013
# E-mail: xhire@mujmalysvet.cz
#####

require 'bigdecimal'

class PluginBcDiff2rate
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'bc_diff2rate'
    @cmd  = 'd2r'
    @help = 'calculate hashrate of Bitcoin network for given difficulty'
  end

  def run channel, params = ''
    diff = BigDecimal.new(params)
    if diff.zero?
      $bot.put "PRIVMSG #{channel} :Error! No difficulty number given!"
    else
      hashrate = diff * 2**32 / 600
      $bot.put "PRIVMSG #{channel} :" + format_rate(hashrate)
    end
  end

  private
  def format_rate hr
    unit = 0
    %w[ Thps Ghps Mhps khps hps ].each_with_index do |unit, i|
      return "#{(hr / 1000 ** (4 - i)).round(3).to_s('F')} #{unit}" if hr > 1000 ** (4 - i)
    end
  end
end
