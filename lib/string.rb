#####
## RubIRCot
###
#> lib/string.rb
#~ This is String extensions library
####
# Author: Michal Zima, 2011
# E-mail: xhire@mujmalysvet.cz
#####
# encoding: utf-8
#####

class String
  # camelize originally taken from ActiveSupport
  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      self.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      self.to_s[0].chr.downcase + self.camelize[1..-1]
    end
  end
end
