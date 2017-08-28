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
    @help = 'tells crypto donation addresses'
  end

  def run channel, params = ''
    $bot.put "PRIVMSG #{channel} :Please send your donation to 1Gx7EqWqoq6xTNKDFc5HWiz1ECNtWpubBo or Lh4wg6Dp8XhfXZtY97pMeBs1Kpxj9TkpZD"
  end
end
