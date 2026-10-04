# A bare `Array.new` as the seed of inject, reduce or sum is the empty
# literal, as it is when a method is called on it. The accumulator took its
# kind from the receiver while the untyped seed was built boxed, so
# `[1, 2].inject(Array.new) { |m, v| m << v }` did not build.
p [1, 2, 3].inject(Array.new) { |m, v| m << v }
p [1, 2, 3].reduce(Array.new) { |m, v| m + [v] }
p [1.5, 2.5].inject(Array.new) { |m, v| m.push(v) }
p ["a", "b"].inject(Array.new) { |m, v| m.unshift(v) }
p [[1, 2], [3]].inject(Array.new) { |m, v| m + v }
p [[1, 2], [3]].reduce(Array.new) { |m, v| m.concat(v) }
p (1..3).inject(Array.new) { |m, v| m << v * 2 }
p({ a: 1, b: 2 }.inject(Array.new) { |m, (k, v)| m << v })
p [[1], [2]].sum(Array.new)
p [["a"], ["b"]].sum(Array.new)

# the table in a local, the fold in a method, the answer kept and grown
t = [4, 5]
x = t.inject(Array.new) { |m, v| m << v }
x << 6
p x, x.size, t
def collect(t) = t.reduce(Array.new) { |m, v| m << v }
p collect([7, 8]), collect([1.5])
p [1].take(0).inject(Array.new) { |m, v| m << v }

# each call builds its own seed
a = [1].inject(Array.new) { |m, v| m << v }
b = [2].inject(Array.new) { |m, v| m << v }
p a, b, a.equal?(b)

# an Array.new with an argument, and the empty literal, are as they were
p [1, 2].inject(Array.new(1, 0)) { |m, v| m << v }
p [1, 2].inject([]) { |m, v| m << v }
