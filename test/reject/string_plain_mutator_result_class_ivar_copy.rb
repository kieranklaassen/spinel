# Both instance variables hold a String handle here, but the write wraps
# the call's bytes in a handle of its own: @r is a copy, and an upcase!
# through it would not reach @s (CRuby [" AB XY", " AB XY"], Spinel
# [" ab xy", " AB XY"]): refused, as `@r = @s.strip!` is.
class Box
  def initialize(s) = @s = s

  def add(a, b)
    @r = @s.concat(a, b)
    @r.upcase!
    [@s, @r]
  end
end
p Box.new(+" ab ").add("x", "y")
