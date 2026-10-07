# An attribute written only by `o.x ||= v` / `o.x &&= v` had a slot no write
# typed, so it was boxed, and `r.x << "z"` appended to a copy of the boxed
# String: the append was lost and nothing said so. Written `o.x = v` the slot
# is a String's. A slot is typed as that write types it where no other name
# can reach its String: each conditional write is a statement given a fresh
# String, each read is used up where it stands, and each mutator stands after
# the `||=` on the same receiver.

class Box
  attr_accessor :x, :y
end

r = Box.new
p r.x
r.x ||= +"ab"
r.x << "z"
p r.x

# `&&=` on the slot that now holds one; an append in a loop and under a
# condition, a chain of appends, a mutator that is not an append
r.x &&= +"cd"
i = 0
while i < 3
  r.x << i.to_s
  i += 1
end
r.x << "-" << "!" unless r.x.empty?
r.x.upcase!
p r.x, r.x.size, r.x == "CD012-!", r.x + "?"
puts "x=#{r.x}"

# a String built by interpolation, by String.new and by a dup
r.y ||= "n#{1}"
r.y << "+"
u = Box.new
u.x ||= String.new
u.x << "new"
u.y ||= "lit".dup
u.y << "!"
p r.y, u.x, u.y

# an object never written still reads nil
p Box.new.x

# the constructor sets nil first, and the method appends through self
class Named
  attr_accessor :name

  def initialize
    @name = nil
  end

  def tag
    self.name ||= +"anon"
    name << "?"
    self
  end
end

p Named.new.tag.tag.name

# the attribute comes from a superclass and from a module
class Base
  attr_accessor :x
end

class Leaf < Base
end

module Titled
  attr_accessor :title
end

class Page
  include Titled
end

l = Leaf.new
l.x ||= +"leaf"
l.x << "!"
pg = Page.new
pg.title ||= +"t"
pg.title << "1"
p l.x, pg.title, Base.new.x

# A String another name reaches keeps the boxed slot, which hands every
# reader the one String: a freeze through that name is still seen.
class Kept
  attr_accessor :s
end

k = Kept.new
k.s ||= +"keep"
t = k.s
t.freeze
begin
  k.s << "!"
rescue FrozenError
  puts "frozen"
end
p k.s, k.s.frozen?
