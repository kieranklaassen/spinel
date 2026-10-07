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

# a receiver with no clear of its own is asked for its class before any
# frozen flag is read: a Regexp's pattern has no collector header
r = { "v" => /a/, "o" => Pt.new(3), "a" => [1, 2], "n" => 1 }
%w[v o].each do |k|
  begin
    r[k].clear
    puts "cleared"
  rescue NoMethodError
    puts "NoMethodError"
  end
end
p r["a"].size, r["o"].x

# a Symbol-keyed Hash of mixed values and a Hash of mixed keys: frozen they
# raise, not frozen they are emptied and take new entries
sf = { a: 1, b: "x" }.freeze
pf = { 1 => "a", "b" => 2 }.freeze
sm = { a: 1, b: "x" }
pm = { 1 => "a", "b" => 2 }
k = { "sf" => sf, "pf" => pf, "sm" => sm, "pm" => pm, "n" => 1 }
%w[sf pf sm pm].each { |n| t { k[n].clear } }
sm[:c] = 3
pm[2] = "z"
p sf.size, pf.size, sm.size, sm[:c], pm.size, pm[2]

# every kind that is not frozen is emptied through the box as it was, and
# takes new elements; a String, a Queue, nil and a number answer as they did
u = { "ia" => [1, 2], "fa" => [1.5], "sa" => ["x"], "oa" => [Pt.new(1)],
      "si" => { "a" => 1 }, "ss" => { "a" => "b" }, "is" => { 1 => "b" },
      "ii" => { 1 => 2 }, "n" => 1 }
%w[ia fa sa oa si ss is ii].each { |n| t { u[n].clear } }
u["ia"] << 7
u["si"]["z"] = 9
p u["ia"], u["fa"], u["sa"], u["oa"].size, u["si"].to_a, u["ss"].size, u["is"].size, u["ii"].size
sb = +"ab"
sb << "cd"
q = Queue.new
q << 1
w = { "sb" => sb, "sl" => "lit", "q" => q, "nil" => nil, "n" => 1 }
%w[sb sl q nil n].each { |n| t { w[n].clear } }
p sb, q.size
