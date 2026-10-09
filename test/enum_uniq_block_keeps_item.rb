# spinel: gc-stress
# uniq with a block over an Enumerator keeps the items its steps yield. The
# block's parameter is what a step hands a block of that shape (a lone |x|
# the first value, a lone |*r| every value); the survivor is the item.

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
p e.uniq { |*r| r << 1; r[0] }

# a block that changes its String parameter in place: a step that yields one
# value has the parameter for its item, so the String kept is the changed one
l = "a\nb\na\n".each_line
p l.uniq { |x| x.chomp!; x }
s = [+"a", +"b", +"a"]
p s.each.uniq { |x| x << "!"; x[0] }
g = Enumerator.new { |y| y.yield(+"a\n"); y.yield(+"a\n", 1); y.yield(+"b\n") }
p g.uniq { |x| x.chomp!; x }
