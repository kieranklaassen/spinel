# delete through a boxed receiver raises FrozenError for an element a
# frozen Array holds, and leaves the Array as it was. An element it does
# not hold answers nil, or the block's value.
def t
  p yield
rescue => e
  puts e.class
end

a = [1, "x", nil].freeze
s = [:a, :b].freeze
h = { "a" => a, "s" => s, "n" => 1 }

t { h["a"].delete(1) }
t { h["a"].delete("x") }
t { h["a"].delete(nil) }
t { h["s"].delete(:b) }
t { h["a"].delete("x") { "none" } }
p a, s

t { h["a"].delete(9) }
t { h["a"].delete(:q) }
t { h["s"].delete(:z) }
t { h["a"].delete(9) { "none" } }
p a, s

# an Array that is not frozen is deleted from as before
u = [1, "x", nil, 1]
g = { "u" => u, "n" => 1 }
t { g["u"].delete(1) }
t { g["u"].delete(7) }
p u
