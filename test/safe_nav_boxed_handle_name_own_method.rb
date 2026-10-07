# A `&.` call on a value read out of a container, to a method of the
# program's own class or of a native class whose name a MatchData also
# answers.
require "strscan"

class Tok
  attr_reader :string
  def initialize(s) = @string = s
  def begin(n) = n + 1
  def captures = [@string]
end

t = [Tok.new("ab"), nil][ARGV.size]
u = [nil, Tok.new("ab")][ARGV.size]
p t&.string, t&.begin(1), t&.captures
p u&.string, u&.begin(1), u&.captures
p t&.string&.size, u&.string&.size

m = ["xab".match(/a(b)/), nil][ARGV.size]
p m&.begin(1), m&.captures

s = [StringScanner.new("ab cd"), nil][ARGV.size]
v = [nil, StringScanner.new("ab cd")][ARGV.size]
s&.scan(/ab/)
p s&.string, s&.pre_match, s&.post_match
p v&.string, v&.pre_match, v&.post_match
