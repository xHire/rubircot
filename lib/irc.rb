#####
## RubIRCot
###
#> lib/irc.rb
#~ This is IRC library but implements some bot's stuff as well
####
# Author: Michal Zima, 2008
# E-mail: xhire@tuxportal.cz
#####

class RubIRCot
  attr_reader :config

  def initialize
    ## Load config files
    @config = YAML.load_file 'conf/main.conf'
  end

  def connect
    @socket = TCPSocket.open @config[:host], @config[:port]
    self.invitation
    self.join @config[:channel]
  end

  def quit
    self.put "PART ##{@config[:channel]} GoodBye!"
    @socket.close
  rescue Errno::EPIPE
    puts '[W] Quit: Socket is already dead'
  end

  def invitation
    # eh.. what does this message means?
    self.put "USER #{@config[:user]} RubIRCot #{@config[:host]} :#{@config[:nick]}"
    self.put "NICK #{@config[:nick]}"
    # wait until they invite us
    # :calkins.freenode.net 376 SimpleRubyBot :End of /MOTD command.
    code = ''
    until code == '376'
      msg = nil
      msg = self.recv.match(/^:(\S+) (\d{3}) (\w*) :(.*)$/) while msg == nil
      @server = msg[1]
      code = msg[2]
    end
  end

  def recv
    msg = @socket.readline.chomp
    puts "[R] #{msg}" if @config[:debug]
    return msg
  end

  def get
    parse self.recv
  end

  def put msg
    @socket.puts msg
    puts "[T] #{msg}" if @config[:debug]
  end

  def parse msg
    ## format of ping
    #< PING :calkins.freenode.net
    #x> PONG calkins.freenode.net :ipv6.chat.freenode.net
    #> :calkins.freenode.net PONG calkins.freenode.net :ipv6.chat.freenode.net
    #T :calkins.freenode.net PONG calkins.freenode.net :ipv6.chat.freenode.net

    #< PING irc.freenode.net
    #> :card.freenode.net PONG card.freenode.net :irc.freenode.net

    #< PING irc.felk.cvut.cz
    #> :irc.felk.cvut.cz PONG irc.felk.cvut.cz :irc.felk.cvut.cz

    #< PING irc.linuxfromscratch.org
    #> :irc.linuxfromscratch.org PONG irc.linuxfromscratch.org :irc.linuxfromscratch.org
    res = msg.match /^PING :(.*)$/
    unless res == nil
      #self.put ":#{@hostserver} PONG #{@hostserver} :#{@config[:host]}"
      self.put ":#{res[1]} PONG #{res[1]} :#{res[1]}"
    end

    ## format of normal message in channel
    # :xHire!n=xHire@2001:470:9985:1:200:e2ff:fe7f:414 PRIVMSG #rubybot :ahoj
    #res = msg.match /^:([^\s]+) ([A-Z]+) #([^\s]*) :(.*)$/
    res = msg.match /^:([^\s]+) (PRIVMSG) #([^\s]*) :(.*)$/
    unless res == nil
      #user = res[1]
      #cmd = res[2]
      channel = '#'+ res[3]
      text = res[4]
      if text[0,1] == @config[:cmdchar]
        bigcmd = text.match(/#{@config[:cmdchar]}([^\s]+)[ ]?(.*)/)
        if bigcmd
          cmd = bigcmd[1]
          params = bigcmd[2]
          #puts "[D] BigCMD: #{bigcmd}"
          #puts "[D] CMD: #{cmd}"
          #puts "[D] PARAMS: #{params}"
          # do it
          # search a plugin
          if $plugins[cmd]
            # run the plugin
            $plugins[cmd].run channel, params
          else
            puts '[D] !'+ cmd +'[unimplemented]'
            self.put "PRIVMSG #{channel} :#{cmd} is not yet implemented"
          end
        end
      end
    end

    ## format private message
    #< :freenode-connect!freenode@freenode/bot/connect PRIVMSG rubanek :#VERSION#'
    #< :freenode-connect!freenode@freenode/bot/connect PRIVMSG xhire :.VERSION.
    #> NOTICE freenode-connect :.VERSION Gaim IRC.
    res = msg.match /^:([^\s]+) (PRIVMSG) ([^\s]*) :(.*)$/
    unless res == nil
      user = self.user res[1]
      channel = res[3]
      text = res[4]
      if text =~ /^.*VERSION.*$/
        # response
        self.put "NOTICE #{user[:nick]} :.VERSION RubIRCot."
      elsif channel == @config[:nick]
        text = text[1..-1] if text[0,1] == @config[:cmdchar]
        bigcmd = text.match(/([^\s]+)[ ]?(.*)/)
        if bigcmd
          cmd = bigcmd[1]
          params = bigcmd[2]
          # search a plugin
          if $plugins[cmd]
            # run the plugin
            $plugins[cmd].run user[:nick], params
          else
            puts '[D] !'+ cmd +'[unimplemented]'
            self.put "PRIVMSG #{user[:nick]} :#{cmd} is not yet implemented"
          end
        end
      elsif text =~ /^#{@config[:nick]}:.*$/ || text =~ /^#{@config[:nick]} :.*$/
        self.put "PRIVMSG #{channel} :#{user[:nick]}: try #{@config[:cmdchar]}help"
      end
    end
  end

  def user str
    user = str.match /^([^\s!]+)(?:!([^\s@]+)@(\S+))?$/
    ret = {
      :nick => user[1],
      :name => user[2],
      :host => user[3]
    }
  end

  def join channel
    self.put "JOIN ##{channel}"
  end

  def ping
    # PING rajaniemi.freenode.net
    self.put "PING #{@server}"
    msg = self.recv
    #res = msg.match /^:([^\s]+) (PONG) ([^\s]*) :(.*)$/
  end
end
