# In a class too, an instance variable that keeps the result of concat with
# several arguments holds a copy of the receiver's String, so an upcase!
# through it would not reach @s (CRuby "ABXY", Spinel "abxy"): refused, as
# `@r = @s.strip!` is.
class Box
  def initialize = @s = +"ab"

  def shout
    @r = @s.concat("x", "y")
    @r.upcase!
    @s
  end
end
p Box.new.shout
