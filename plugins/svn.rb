#####
## RubIRCot
###
#> plugin/svn.rb
#~ Plugin that provides info about the latest (if not specified) SVN revision
####
# Author: Michal Zima, 2008
# E-mail: xhire@tuxportal.cz
#####

class PluginSvn
	attr_reader :name
	attr_reader :cmd
	attr_reader :help

	def initialize
		@name = 'svn'
		@cmd  = 'svn'
		@help = 'get log of last revision'
	end

	def run channel, params = ''
		cache = '/tmp/rubircot_svn.cache'
		# get the revision number
		unless params =~ /^\d+$/
			system "wget #{$bot.config[:svn]} -O #{cache} -q"
			rev = IO.readlines(cache)[0]
			rev.sub!(/.*Revision (\d+):.*/, '\1').chomp!
		else
			rev = params.chomp
		end

		# get the log of the revision
		system "svn log -r #{rev} #{$bot.config[:svn]} > #{cache}"
		logfile = IO.readlines(cache)
		ll = logfile.length - 1
		0.upto ll do |l|
			# skip empty lines
			if l == 0 || l == ll
				next
			end
			if logfile[l] == "\n"
				next
			end

			# send log & msg
			$bot.put "PRIVMSG #{channel} :#{logfile[l]}"
		end
	end
end
