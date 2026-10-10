# A Float splatted into values_at is the index it is, and a NaN there is
# CRuby's RangeError. Where the program reopens RangeError and gives it an
# `initialize`, CRuby runs that for the error too, and the rescue here
# prints what the call printed while the splat gave none. A `raise` the
# program writes runs such an `initialize` and a raise by the runtime does
# not, so in a program that reopens a builtin exception class the splat is
# read as before.
class RangeError
  def initialize(m = nil)
    super("[]")
  end
end
a = [[10, 20, 30], nil][ARGV.size]
f = 0.0 / 0.0
begin
  p a.values_at(*f)
rescue => e
  puts e.message
end
