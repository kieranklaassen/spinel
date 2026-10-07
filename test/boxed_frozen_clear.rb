# clear through a boxed receiver raises for a frozen Array or Hash and
# leaves it as it was (it emptied it and said nothing)
def t
  yield
  puts "cleared"
rescue => e
  puts e.class
end

class Pt
  attr_reader :x
  def initialize(x) = @x = x
end

a = [1, 2].freeze
b = [1.5].freeze
c = ["x"].freeze
d = [1, "x", nil].freeze
e = [Pt.new(1), Pt.new(2)].freeze
f = [:a, :b].freeze
hs = { "a" => 1 }.freeze
hh = { "a" => "b" }.freeze
hi = { 1 => "b" }.freeze
hp = { "a" => 1, "b" => "c" }.freeze
h = { "a" => a, "b" => b, "c" => c, "d" => d, "e" => e, "f" => f,
      "hs" => hs, "hh" => hh, "hi" => hi, "hp" => hp, "n" => 1 }

%w[a b c d e f hs hh hi hp].each { |k| t { h[k].clear } }
p a, b, c, d, e.size, f
p hs.size, hh.size, hi.size, hp.size

# the message names the receiver
begin
  h["d"].clear
rescue FrozenError => err
  puts err.message
end

# through a parameter that takes an Array or a Hash
def wipe(v) = v.clear
t { wipe(d) }
t { wipe(hp) }
p d, hp.size

# an empty frozen Array raises too
z = [].freeze
g = { "z" => z, "n" => 1 }
t { g["z"].clear }

# one that is not frozen is emptied, and the Array itself is
x = [1, "x"]
y = { "a" => 1, "b" => "c" }
m = { "x" => x, "y" => y, "n" => 1 }
t { m["x"].clear }
t { m["y"].clear }
t { wipe(x) }
p x, y.size
