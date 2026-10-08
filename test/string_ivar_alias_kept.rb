# The assignments beside the refused `@t = @s` and `@t = s.to_s` that
# build and answer as CRuby does: the refusal asks only two String names
# that are not one handle, one mutated in place and the other read.

# `@t = s` and `t = @s` are one handle
s = +"ab"
@t = s
s << "x"
@t << "y"
p @t, s
class Box
  def initialize = @s = +"ab"
  def go
    t = @s
    t << "x"
    u = @s.to_s
    u << "y"
    p @s
  end
end
Box.new.go

# `to_s` of what is no String makes a new one
@n = 5
@m = @n.to_s
@m << "x"
p @n, @m
class Sym
  def initialize = @n = :ab
  def go
    @t = @n.to_s
    @t << "x"
    p @n, @t
  end
end
Sym.new.go

# a copy that is only read
@a = +"ab"
@b = @a
@c = @a.to_s
p @b, @c, @a.size

# the same two names in another class, where neither is assigned from the other
class Pair
  def initialize = @s = +"ab"
  def go
    @t = @s
    p @t, @s
  end
end
class Apart
  def initialize = (@s = +"cd"; @t = +"ef")
  def go
    @t << "x"
    @s << "y"
    p @t, @s
  end
end
Pair.new.go
Apart.new.go
