#####
## RubIRCot
###
#> plugin/git.rb
#~ Plugin that provides info about the latest GIT commit
####
# Author: Michal Zima, 2008-2009
# E-mail: xhire@tuxportal.cz
#####

class PluginGit
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'git'
    @cmd  = 'git'
    @help = 'get log of last commit'
  end

  def run channel, params = ''
    cache = '/tmp/rubircot/git/'
    gitdir = $bot.config[:git].sub /.*\//, ''
    logfile = cache + gitdir + '.log'

    # create the directory for cache if necessary
    system "mkdir -p #{cache}"
    Dir.chdir cache

    # get the repository
    if File.exist?(cache + gitdir)
      Dir.chdir gitdir
      system "git pull"
    else
      system "git clone #{$bot.config[:git]} #{gitdir}"
      Dir.chdir gitdir
    end

    # get the log
    system "git log -n 1 > #{logfile}"

    # parse the log
    log = IO.readlines logfile
    author = log[1].match(/^Author:\s*(.*)$/)[1]
    date   = log[2].match(/^Date:\s*(.*)$/)[1]
    msg    = log[4].match(/^\s*(.*)$/)[1]

    # send the data
    $bot.put "PRIVMSG #{channel} :#{author} at #{date}: #{msg}"
  end
end
