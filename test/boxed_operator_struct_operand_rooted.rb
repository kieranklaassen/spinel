# The operand of a boxed operator is boxed where it is handed over. A
# Rational is a struct in C and its box is a cell, so a literal or a typed
# local allocates there: between a receiver made in place and the call, or
# ahead of a receiver that allocates, with the box held by nothing. Under
# SPINEL_GC_STRESS=2 `mk(1) + 2r` answered (4/3) for (8/3).

def mk(i) = [Rational(i + 1, 3), :a][0]
def idv(x) = x
idv(:s)
q = Rational(5, 7)

def show(rs) = p(rs.select.with_index { |_, k| k.even? })

rs = []
4.times { |i| rs << mk(i) + 2r; rs << [i, i.to_s] }
4.times { |i| rs << mk(i) - 2r; rs << [i, i.to_s] }
4.times { |i| rs << mk(i) * 3r; rs << [i, i.to_s] }
4.times { |i| rs << mk(i) / 2r; rs << [i, i.to_s] }
4.times { |i| rs << mk(i) % 2r; rs << [i, i.to_s] }
show(rs)

# a typed local is boxed the same way
rs = []
4.times { |i| rs << mk(i) + q; rs << [i, i.to_s] }
4.times { |i| rs << idv(Rational(i, 3)) * q; rs << [i, i.to_s] }
show(rs)

# the named divisions
rs = []
4.times { |i| rs << mk(i).divmod(2r); rs << [i, i.to_s] }
4.times { |i| rs << mk(i).quo(2r); rs << [i, i.to_s] }
4.times { |i| rs << mk(i).fdiv(2r); rs << [i, i.to_s] }
4.times { |i| rs << mk(i).remainder(q); rs << [i, i.to_s] }
show(rs)

# comparisons
rs = []
4.times { |i| rs << (mk(i) < 1r); rs << [i, i.to_s] }
4.times { |i| rs << (mk(i) >= q); rs << [i, i.to_s] }
4.times { |i| rs << (mk(i) == 1r); rs << [i, i.to_s] }
4.times { |i| rs << (mk(i) != q); rs << [i, i.to_s] }
4.times { |i| rs << (mk(i) <=> 1r); rs << [i, i.to_s] }
show(rs)

# held already: a receiver read from a variable, an Array, an object or a Hash
Box = Struct.new(:v)
x = mk(3)
a = [mk(4), :x]
o = Box.new(mk(5))
h = { k: mk(6), j: :y }
rs = []
4.times { |i| rs << x + 2r; rs << a[0] * q; rs << (o.v < 2r); rs << h[:k] - q; rs << [i, i.to_s] }
p rs.reject { |v| v.is_a?(Array) }
