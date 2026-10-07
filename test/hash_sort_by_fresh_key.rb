# Hash#sort_by with a block whose value is a fresh String or Array. The
# value was held by a C temporary alone while the [sort_key, pair] tuple
# was allocated, so a collection that fell there freed it before it was
# stored: pairs came out of order, or two freed Arrays failed to compare.

t = "x"

# the calls that reach the Hash sort_by lowering, and the block forms
h = {"b" => "y", "a" => "z", "c" => "x"}
p h.sort_by { |k, v| v + t }
p h.sort_by { |k, v| [v.size, v + t] }
p h.sort_by { |k, v| "#{v}-#{k}" }
p h.sort_by { |k, v| v.size > 5 ? 0 : v + t }
p h.sort_by { |k, v| v + t }.to_h.keys
p h.sort_by { |k, v| v + t }.first(2)
p h.min_by(2) { |k, v| v + t }
p h.min_by(2) { |k, v| [v + t] }
p h.sort_by { |pair| pair[1] + t }
p h.sort_by { |(k, v)| k + v }
p h.sort_by { _2 + t }

g = {1 => 1, 2 => 2, 3 => 7}
puts g.sort_by { |k, _v| k.to_s }.size
p g.sort_by { |k, v| (10 - v).to_s }
p g.sort_by { |k, v| [v.to_s, k] }

s = {a: 2.5, b: 0.5, c: 1.5}
p s.sort_by { |k, v| v.to_s }
p s.sort_by { |k, v| k.to_s + t }.map { |k, v| v }

# a scalar from a block that allocates on its way: nothing is held then
p g.sort_by { |k, v| (v.to_s * (4 - k) + t).size }
p s.sort_by { |k, v| (v.to_s + t).to_f }
p h.sort_by { |k, v| w = v + t; w.to_sym }

# sort keys that tie: only the value column, CRuby's sort_by is not stable
d = {"p" => "b", "q" => "a", "r" => "b", "s" => "a", "u" => "c"}
p d.sort_by { |k, v| v + t }.map { |k, v| v }
p d.sort_by { |k, v| [v + t] }.map { |k, v| v }

e = {"z" => "z"}
e.delete("z")
p e.sort_by { |k, v| k.to_s + t }

# one Hash of Integers sorted six times: how many sorts are out of order
ih = {}
500.times { |i| ih[(i * 7919) % 30011] = i }
bad = 0
6.times do
  r = ih.sort_by { |k, _v| k.to_s.rjust(40, "0") }
  ok = r.size == 500
  i = 1
  while ok && i < r.size
    ok = false if r[i - 1][0] >= r[i][0]
    i += 1
  end
  bad += 1 unless ok
end
puts "by a padded String, six times: #{bad} wrong"
bad = 0
6.times do
  r = ih.sort_by { |k, v| [v % 7, k] }
  ok = r.size == 500
  i = 1
  while ok && i < r.size
    a = r[i - 1]
    b = r[i]
    ok = false if ([a[1] % 7, a[0]] <=> [b[1] % 7, b[0]]) >= 0
    i += 1
  end
  bad += 1 unless ok
end
puts "by an Array of two Integers, six times: #{bad} wrong"

# enough entries, at several sizes, for a collection to fall between the
# block and the store in a plain run
def build(n)
  h = {}
  i = 0
  while i < n
    h["k" + i.to_s.rjust(6, "0")] = "v" + (n - 1 - i).to_s.rjust(6, "0")
    i += 1
  end
  h
end

def out_of_place(r)
  n = r.size
  bad = 0
  i = 0
  while i < n
    bad += 1 if r[i][0] != "k" + (n - 1 - i).to_s.rjust(6, "0")
    i += 1
  end
  bad
end

n = 1000
while n <= 8000
  big = build(n)
  puts "#{n} by an Integer: #{out_of_place(big.sort_by { |k, v| (v + t)[1, 6].to_i })} out of place"
  n += 1000
end
n = 1000
while n <= 8000
  big = build(n)
  puts "#{n} by a String: #{out_of_place(big.sort_by { |k, v| v + t })} out of place"
  n += 1000
end
n = 1000
while n <= 8000
  big = build(n)
  puts "#{n} by an Array: #{out_of_place(big.sort_by { |k, v| [v.size, v] })} out of place"
  n += 1000
end
