# Array#delete on a frozen Array raises only for an element it would
# remove. An element the Array does not hold answers nil, or the block's
# value, as it does on an Array that is not frozen.
def t
  p yield
rescue => e
  puts e.class
end

a = ["x", "y"].freeze
b = [1, 2].freeze
c = [1.5, 2.5].freeze
d = [:a, :b].freeze
e = [1, "x", nil].freeze

t { a.delete("zz") }
t { b.delete(9) }
t { c.delete(9.5) }
t { d.delete(:z) }
t { e.delete(9) }
t { a.delete("zz") { "none" } }
t { b.delete(9) { "none" } }
t { e.delete(:q) { "none" } }
t { b.delete(nil) }
t { b.delete("x") }

# an element it holds raises, and the Array is as it was
t { a.delete("x") }
t { b.delete(2) }
t { b.delete(2.0) }
t { c.delete(1.5) }
t { d.delete(:b) }
t { e.delete(nil) }
t { e.delete("x") { "none" } }
p a, b, c, d, e

# through a boxed receiver
h = { "i" => [1, 2].freeze, "s" => ["a"].freeze, "n" => 1 }
t { h["i"].delete(7) }
t { h["s"].delete("z") }
t { h["i"].delete(1) }
t { h["s"].delete("a") }
p h["i"], h["s"]
