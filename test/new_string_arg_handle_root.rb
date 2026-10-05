# A String handed to new for a String changed in place is kept alive.
# Such a member holds its String through a handle, and a String that is not
# one already gets a handle of its own where it is handed over. Nothing held
# that handle while the argument beside it, or the object itself, was
# allocated. Each line counts the objects that came out holding another
# String; the last one shows the members are changed in place.
N = 20_000

class Pair
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
  def self.of(a, b) = new(a, b)
  def is?(odd) = odd ? @x == "s" && @y == "t" : @x == "q" && @y == "r"
  # The String is read where the argument stands: what the statement
  # writes ahead of it has been written.
  def self.sum(s) = (s = "bb") + new(s, "t").x
  def self.text(s) = "#{(s = "bb")}-#{new(s, "t").x}"
  def self.two(s)
    return (s = "bb"), new(s, "t").x
  end
  def self.late(s)
    return s, (s = "bb"; new("x", "t").x)
  end
  # Two objects made in the tail of a sequence leave it where it stands too.
  def self.late_two(s)
    return s, (s = "bb"; new("x", "2").x + new("y", "3").y)
  end
  def self.late_text(s) = "#{s}|#{(s = "bb"; new("x", "2").x + new("y", "3").y)}"
end

class Named
  attr_reader :x
  def initialize(x:) = @x = x
  def is?(odd) = @x == (odd ? "s" : "q")
end

class Tail
  attr_reader :x, :y
  def initialize(x, y = "r")
    @x = x
    @y = y
  end
  def is?(odd) = @x == (odd ? "s" : "q") && @y == "r"
end

class Maker
  def initialize(a, b)
    @a = a
    @b = b
  end
  def pair = Pair.new(@a, @b)
end

class String
  def with(other) = Pair.new(self, other)
end

Q = "q"
R = "r"
S = "s"
T = "t"

def pair_of(a, b) = Pair.new(a, b)

d = Pair.new(+"w", +"v")
d.x << "z"
d.y << "z"
e = Named.new(x: +"w")
e.x << "z"
g = Tail.new(+"w", +"v")
g.x << "z"
g.y << "z"

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

qr = Maker.new("q", "r")
st = Maker.new("s", "t")
ra = ["r"]
ta = ["t"]
qa = ["q"]
sa = ["s"]

p wrong(N) { |odd| odd ? Pair.new("s", "t") : Pair.new("q", "r") }   # literals
p wrong(N) { |odd| odd ? Named.new(x: "s") : Named.new(x: "q") }     # a literal by keyword
p wrong(N) { |odd| odd ? Pair.new(S, T) : Pair.new(Q, R) }           # constants
p wrong(N) { |odd| odd ? Pair.of("s", "t") : Pair.of("q", "r") }     # parameters of a class method
p wrong(N) { |odd| odd ? pair_of("s", "t") : pair_of("q", "r") }     # parameters of a method
p wrong(N) { |odd| odd ? st.pair : qr.pair }                         # instance variables
p wrong(N) { |odd| odd ? "s".with("t") : "q".with("r") }             # self
p wrong(N) { |odd| odd ? Pair.new("s", *ta) : Pair.new("q", *ra) }   # an Array's element, splatted
p wrong(N) { |odd| odd ? Tail.new(*sa) : Tail.new(*qa) }             # a splat that leaves a default to fill
p [d.x, d.y, e.x, g.y]
p Pair.sum("a"), Pair.text("a"), Pair.two("a"), Pair.late("a")
p Pair.late_two("a"), Pair.late_text("a")
