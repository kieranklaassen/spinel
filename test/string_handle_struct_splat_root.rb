# A String handed to a member or a parameter that is changed in place gets
# a handle of its own where it is handed over. Nothing held that handle
# when the String went to a Struct's member, or came out of a splatted
# Array, while the argument beside it or the object itself was allocated.
# Each line counts the objects that came out holding another String; the
# last one shows the members are changed in place.
N = 20_000

class Pair
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
  def is?(odd) = odd ? @x == "s" && @y == "t" : @x == "q" && @y == "r"
end

class Tail
  attr_reader :x, :y
  def initialize(x, y = "r")
    @x = x
    @y = y
  end
  def is?(odd) = @x == (odd ? "s" : "q") && @y == "r"
end

Entry = Struct.new(:a, :b)

d = Pair.new(+"w", +"v")
d.x << "z"
d.y << "z"
g = Tail.new(+"w", +"v")
g.x << "z"
g.y << "z"
w = +"w"
v = +"v"
e = Entry.new(w, v)
e.a << "z"
e.b << "z"

# Each object is looked at one construction later, when a String it lost
# has been handed out again.
def wrong(n)
  bad = 0
  prev = nil
  n.times do |i|
    k = yield(i.odd?)
    bad += 1 if prev && !prev.is?(i.even?)
    prev = k
  end
  bad
end

def wrong_entries(n)
  bad = 0
  prev = nil
  n.times do |i|
    k = yield(i.odd?)
    if prev
      good = i.even? ? prev.a == "s" && prev.b == "t" : prev.a == "q" && prev.b == "r"
      bad += 1 unless good
    end
    prev = k
  end
  bad
end

ra = ["r"]
ta = ["t"]
qa = ["q"]
sa = ["s"]

# Kept, the objects are looked at when all of them are made.
kept = []
3000.times { kept << Entry.new("alpha", "beta") }
p kept.count { |k| k.a != "alpha" || k.b != "beta" }
pairs = []
3000.times { pairs << Pair.new("q", *ra) }
p pairs.count { |k| k.x != "q" || k.y != "r" }

p wrong(N) { |odd| odd ? Pair.new("s", *ta) : Pair.new("q", *ra) }            # an Array's element, splatted
p wrong(N) { |odd| odd ? Tail.new(*sa) : Tail.new(*qa) }                      # a splat that leaves a default to fill
p wrong_entries(N) { |odd| odd ? Entry.new("s", "t") : Entry.new("q", "r") }  # literals to a Struct
p [d.x, d.y, g.x, g.y, e.a, e.b, w, v]
