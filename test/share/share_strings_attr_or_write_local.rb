# Flag-only: without the flag the attribute holds a copy of the local's String.
# A String a local holds, stored by an attribute's `o.x ||= s` or
# `o.x &&= s`, is the one the attribute then holds, as with `o.x = s`.
class Box
  attr_accessor :x
end

r = Box.new
s = +"ab"
r.x ||= s
r.x << "z"
p s, r.x

class Tag
  attr_accessor :y
end

g = Tag.new
g.y = +"q"
t = +"cd"
g.y &&= t
g.y << "!"
p t, g.y

# `self.z ||=` given a parameter
class Memo
  attr_accessor :z

  def fill(v)
    self.z ||= v
    self
  end
end

u = +"m"
Memo.new.fill(u).z << "1"
p u
