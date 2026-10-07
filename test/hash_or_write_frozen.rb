# `h[k] ||= v` and `h[k] &&= v` raise FrozenError on a frozen Hash where
# they write, as `h[k] = v` does. The value runs before the raise, and a
# write the guard skips raises nothing.
h = { a: 1 }.freeze
begin
  h[:k] ||= 2
  puts "no raise"
rescue FrozenError => e
  puts e.class
end
begin
  h[:a] &&= 3
  puts "no raise"
rescue FrozenError => e
  puts e.class
end
h[:a] ||= 4
h[:k] &&= 5
p h.to_a

# the write as a value
begin
  x = (h[:k] ||= 6)
  p x
rescue FrozenError => e
  puts e.class
end
p h.size

# the value runs first
def seven
  puts "seven"
  7
end
begin
  h[:k] ||= seven
rescue FrozenError => e
  puts e.class
end

# String keys, String values, and a key that is a call
s = { "a" => "x" }.freeze
k = :b
begin
  s["b"] ||= "y"
rescue FrozenError => e
  puts e.class
end
begin
  s[k.to_s] ||= "z"
rescue FrozenError => e
  puts e.class
end
begin
  y = (s["a"] &&= "w")
  p y
rescue FrozenError => e
  puts e.class
end
p s.to_a

# values of two kinds
m = { "n" => 1, "s" => "t" }.freeze
begin
  m["u"] ||= 2
rescue FrozenError => e
  puts e.class
end
p m.size

# a Hash a method is given
def fill(c)
  c[:z] ||= 0
  c.size
end
p fill({ a: 1 })
begin
  p fill(h)
rescue FrozenError => e
  puts e.class
end

# a default answers the read, so nothing is written
d = Hash.new(0).freeze
d[:k] ||= 1
p d.size

# a Hash that is not frozen is written as before
u = { a: 1 }
u[:k] ||= 2
u[:a] &&= 3
p u.to_a
