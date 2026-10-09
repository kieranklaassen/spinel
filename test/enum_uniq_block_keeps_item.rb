# spinel: gc-stress
# uniq with a block over an Enumerator keeps what its steps yield. The
# block's parameter is what a step hands a block of that shape (a lone |x|
# the first value, a lone |*r| every value); the survivor is the step's one
# value, or a new Array of the values it packed.

def pairs = [5, 6, 5].each_with_index

e = [5, 6, 5].each_with_index
p e.uniq { |x| x }
p e.uniq { |x| 1 }
p e.uniq { _1 }
p e.uniq { |(x, i)| x }
p e.uniq { |*r| r[0] }
p e.uniq { |x, i| i > 0 }
p pairs.uniq { |x| x.to_s }

w = %w[a b a].each_with_index
p w.uniq { |x| x }

# one value a step
o = [5, 6, 5, 7].each
p o.uniq { |x| x }
p o.uniq { |*r| r }
p o.uniq(&:odd?)
a = [[1, 2], [1, 3], [1, 2]].each
p a.uniq { |x| x }
p a.uniq { |x| x[0] }

# an Enumerator known only at run time
def pick(en) = en.uniq { |x| x }
p pick([5, 6, 5].each_with_index)
p pick([5, 6, 5].each)

# steps that yield one value or several
en = Enumerator.new { |y| y.yield 1; y.yield 2, 3; y.yield 1; y.yield 2, 4 }
p en.uniq { |x| x }
p en.uniq { |*r| r }

# a block that changes its String parameter in place: a step that yields one
# value has the parameter for its item, so the String kept is the changed one
l = "a\nb\na\n".each_line
p l.uniq { |x| x.chomp!; x }
s = [+"a", +"b", +"a"]
p s.each.uniq { |x| x << "!"; x[0] }
g = Enumerator.new { |y| y.yield(+"a\n"); y.yield(+"a\n", 1); y.yield(+"b\n") }
p g.uniq { |x| x.chomp!; x }

# what a step packed is the survivor's own Array: changing it leaves the
# Enumerator's items as they were
r = e.uniq { |*q| q[0] }
r[0] << 7
p e.to_a
p e.uniq { |*q| q[0] }
p r[0].equal?(e.to_a[0])
u = e.uniq { |x| x }
u[0] << 7
p e.to_a
p e.uniq { |x| x }
h = { a: 1, b: 2 }
hi = h.each_with_index
t = hi.uniq { |x| x }
t[0] << 7
p t
p hi.to_a

# a block that changes its |*q| is asked ahead of the block, and what a
# survivor is made of is taken ahead of the first step: the block reaches
# the Enumerator's own items through another to_a
en2 = Enumerator.new { |y| y.yield 5, 0; y.yield 6, 1; y.yield 5, 2 }
p en2.uniq { |*q| k = q[0]; q.pop; k }.map { |v| v[0] }
p en2.uniq { |*q| k = q[0]; q.pop; q[0] = 9; k }.include?(9)
e3 = [5, 6, 5].each_with_index
p e3.uniq { |x| e3.to_a[0][0] = 7; x }.map { |v| Array(v)[0] }
