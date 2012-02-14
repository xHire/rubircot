#####
## RubIRCot
###
#> plugin/donate.rb
#~ Plugin that tells Bitcoin donation address
####
# Author: Michal Zima, 2012
# E-mail: xhire@mujmalysvet.cz
#####

class PluginDonate
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'donate'
    @cmd  = 'donate'
    @help = 'tells Bitcoin donation address'
  end

  def run channel, params = ''
    $bot.put "PRIVMSG #{channel} :Please send your donation to 1DsVrJXSrbgbL9AK6o49qDwrZ9gYZkDJK8"
  end
end
