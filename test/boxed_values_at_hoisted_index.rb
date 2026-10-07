# values_at on a boxed receiver collects its indexes one statement each. An
# index that needs a statement of its own (a literal Array, a splatted list)
# has that statement ahead of the one that takes the index, not inside it.

a = [[1, 2, 3], nil][ARGV.size]
p a.values_at(0, [1].size)
p a.values_at([2].first, 0, [1, 1].sum)
p a.values_at(-[1].size)
p a.values_at(0..[1].size)

# a splatted list that is built in place
p a.values_at(*[0, [1].size])
p a.values_at(*[[2].first], [1].size)
p a.values_at(*[0, 1].map { |x| x + 1 })

# a mixed Array and a Hash
b = [[10, "s", :z], nil][ARGV.size]
p b.values_at([1].size, [0, 2].last)
h = [{a: 1, b: 2}, nil][ARGV.size]
p h.values_at([:a].first, :b)
g = [{"a" => 1, "b" => 2}, nil][ARGV.size]
p g.values_at(["a"].first, "b")

# indexes that need no statement answer as before
p a.values_at(0, 2)
i = [1].size
p a.values_at(0, i)
