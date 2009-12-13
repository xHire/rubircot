#####
## RubIRCot
###
#> plugin/help.rb
#~ Plugin that provides help (list of commands) for the user
####
# Author: Michal Zima, 2008
# E-mail: xhire@tuxportal.cz
#####

class PluginHelp
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'help'
    @cmd  = 'help'
    @help = 'get list of all commands'
  end

  def run channel, params = ''
    for plugin in $plugins
      $bot.put "PRIVMSG #{channel} :#{$bot.config[:cmdchar]}#{plugin[1].cmd}\t\t\t#{plugin[1].help}"
    end
    return $plugins
  end

  #def more
    #@help
  #end
end
