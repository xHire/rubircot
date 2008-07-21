#####
## RubIRCot
###
#> plugin/git.rb
#~ Plugin that provides info about the latest GIT revision
####
# Author: Michal Zima, 2008
# E-mail: xhire@tuxportal.cz
#####

class PluginGit
	attr_reader :name
	attr_reader :cmd
	attr_reader :help

	def initialize
		@name = 'git'
		@cmd  = 'git'
		@help = 'get log of last revision'
	end

	def run channel, params = ''
		cache = '/tmp/rubircot_git.cache'
		# get the rss page
		system "wget #{$bot.config[:git]} -O #{cache} -q"
		rss = IO.readlines(cache)
		fl = rss.length - 1
		status = 0
		content = false
		0.upto fl do |l|
			# if we have all information, stop searching
			if status == 3
				break
			end

			# get author
			ra = rss[l].match /^<author>(.*)<\/author>$/
			if ra
				status += 1
				author = ra[1]
				author = author.gsub /&lt;/, '<'
				author = author.gsub /&gt;/, '>'
				$bot.put "PRIVMSG #{channel} :Author: #{author}"
				next
			end

			# get date and adjust it
			rd = rss[l].match /^<pubDate>(.*)<\/pubDate>$/
			if rd
				status += 1
				$bot.put "PRIVMSG #{channel} :Date: #{rd[1]}"
				next
			end

			# get multiline commit message
			if rss[l].chomp == '<pre>'
				content = true
				next
			end

			rc = rss[l].match /^<\/pre>.*$/
			if rc
				status += 1
				content = false
				next
			end

			if content
				$bot.put "PRIVMSG #{channel} :#{rss[l]}"
				next
			end
		end
	end
end

