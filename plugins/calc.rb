#####
## RubIRCot
###
#> plugin/calc.rb
#~ Plugin - simple calculator
####
# Author: Michal Zima, 2008
# E-mail: xhire@tuxportal.cz
#####

class PluginCalc
  attr_reader :name
  attr_reader :cmd
  attr_reader :help

  def initialize
    @name = 'calc'
    @cmd  = 'c'
    @help = 'instant calculator'
  end

  def run channel, params
    unless params =~ /^[-+*\/%\. \d]+$/
      $bot.put "PRIVMSG #{channel} :Error! Bad format!"
      return nil
    end

    maths = [ '**', '//', '*', '/', '%', '+', '-' ]
    number = /(\d+[\.]?[\d]?)(.*)/
    formula = params.tr(' ', '')
    tmp = ''
    for math in maths do
      until formula.to_a == formula.split(math)
        parts = formula.split(math)
        part = []
        term = []

        # fix problem with no terms
        if parts.empty?
          $bot.put "PRIVMSG #{channel} :Error! Unrecognised format!"
          return nil
        end

        part[0] = parts[0].reverse.match number

        # fix problem with minus
        if math == '-' && !part[0]
          tmp = '-'
          formula.sub! /-/, ''
          next
        elsif !part[0]
          $bot.put "PRIVMSG #{channel} :Error! Unrecognised format!"
          return nil
        end

        term[0] = part[0][1].reverse

        # fix problem without second term
        unless parts[1]
          if math == '//'
            parts[1] = '2'
          else
            parts[1] = '0'
          end
        end

        part[1] = parts[1].match number

        # fix problem with bad format (e.g. '///')
        unless part[1]
          $bot.put "PRIVMSG #{channel} :Error! Unrecognised format!"
          return nil
        end

        term[1] = part[1][1]

        # fix problem with division by zero
        if math == '/' && term[1] == '0'
          $bot.put "PRIVMSG #{channel} :Error! Division by zero!"
          return nil
        end

        unless math == '//'
          res = eval "#{tmp}#{term[0]} #{math} #{term[1]}"
          tmp = ''
        else
          res = eval "#{term[0]} ** (1.0/#{term[1]})"
        end

        formula = "#{part[0][2].reverse}#{res}#{part[1][2]}"

        0.upto parts.length - 1 do |part|
          unless part == 0 || part == 1
            formula = "#{formula}#{math}#{parts[part]}"
          end
        end
      end
      formula = "#{tmp}#{formula}"
    end

    $bot.put "PRIVMSG #{channel} :#{formula}"
  end
end
