# A class body runs in the top level's frame, so its match is written to the
# top level's registers. A program that matches in one keeps the registers as
# they are left by a raise: here the miss in `raises` clears them.
class Limits
  MAJOR = ("v3.1" =~ /v(\d)/) ? 3 : 0
end

def raises(s)
  s =~ /nope/
  raise ArgumentError, "x"
end

begin
  raises("zq")
rescue ArgumentError
end
p Limits::MAJOR
p $~
