# An attribute written only by `o.x ||= v` / `o.x &&= v` had a slot no write
# typed, so it was boxed, and `r.x << "z"` appended to a copy of the boxed
# String: the append was lost and nothing said so. Written `o.x = v` the slot
# is a String's. A slot whose conditional writes all give a String is typed
# as that write types it.

class Box
  attr_accessor :x, :y
end

r = Box.new
p r.x
r.x ||= +"ab"
r.x << "z"
p r.x

# through a second name for the slot's String
t = r.x
t << "y"
p r.x

# `&&=` on the slot that now holds one, and an append in a loop
r.x &&= +"cd"
3.times { |i| r.x << i.to_s }
p r.x, r.x.size

# a method that appends to what it is handed
def bang(s) = s << "!"
bang(r.x)
p r.x

# a String built by interpolation and by a call
r.y ||= "n#{1}"
r.y << "+"
p r.y
u = Box.new
u.x ||= String.new
u.x << "new"
u.y ||= 1.to_s
p u.x, u.y

# an object never written still reads nil
p Box.new.x

# the constructor sets nil first
class Named
  attr_accessor :name

  def initialize
    @name = nil
  end

  def tag
    self.name ||= +"anon"
    self.name << "?"
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
pg&.title ||= +"t"
pg.title << "1"
p l.x, pg.title, Base.new.x

# the same attribute name on another class holds an Integer: its slot is its own
class Count
  attr_accessor :x
end

c = Count.new
c.x ||= 5
c.x += 1
p c.x, Count.new.x
