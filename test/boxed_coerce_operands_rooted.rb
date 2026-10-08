# spinel: int64
# coerce on a boxed number allocates the Array it answers with, and the pair
# keeps the operands themselves. A Rational or a Bignum handed over boxed is
# a cell: one made in the argument list, or a receiver made in place, is held
# by nothing else while that Array is made.

def mk(i) = [Rational(i + 1, 3), :a][0]
def big(i) = [2**70 + i, :a][0]
def idv(x) = x
idv(:s)

# the operand is made in the argument list
rs = []
r = [3r / 4, :a][0]
3.times { |i| rs << r.coerce(Rational(i, 1)).inspect }
3.times { |i| rs << r.coerce(Rational(i + 1, 7) + 1).inspect }
3.times { |i| rs << r.coerce(2r).inspect }
puts rs

rs = []
3.times { |i| n = [i + 7, :a][0]; rs << n.coerce(2**70 + i).inspect }
3.times { |i| f = [i + 0.5, :a][0]; rs << f.coerce(Rational(i, 1)).inspect }
puts rs

# the receiver is made in place
rs = []
3.times { |i| rs << mk(i).coerce(2).inspect }
3.times { |i| rs << big(i).coerce(i).inspect }
3.times { |i| rs << idv(Rational(i + 1, 3)).coerce(i + 1.5).inspect }
3.times { |i| rs << idv(2**70 + i).coerce(2**71).inspect }
puts rs

# both are made in place
rs = []
3.times { |i| rs << mk(i).coerce(2r).inspect }
3.times { |i| rs << mk(i).coerce(Rational(i, 1)).inspect }
puts rs

# a typed Rational is a struct in C, copied into a new cell where it is
# boxed: also when it is read from a variable, a parameter or a constant
Q = Rational(5, 7)
def co(r, q) = r.coerce(q)
rs = []
3.times { |i| q = Rational(i + 1, 7); rs << r.coerce(q).inspect }
3.times { |i| rs << co(r, Rational(i + 1, 7)).inspect }
3.times { |i| rs << r.coerce(Q).inspect }
3.times { |i| q = Rational(i + 1, 7); rs << big(i).coerce(q).inspect }
3.times { |i| q = Rational(i + 1, 7); rs << mk(i).coerce(q).inspect }
puts rs

# an element of a variable's Array is held by the Array, until the operand's
# code puts another in its place
def again(a, i)
  a[0] = Rational(i + 2, 5)
  Rational(i + 1, 3)
end
a = [Rational(3, 5), 7, 2**70, 1.5]
rs = []
3.times { |i| rs << a[0].coerce(i + 0.5).inspect }
3.times { |i| rs << a[0].coerce(2r).inspect }
3.times { |i| rs << a[i].coerce(a[2]).inspect }
3.times { |i| rs << r.coerce(a[i]).inspect }
3.times { |i| a[0] = Rational(i + 2, 5); rs << a[0].coerce(again(a, i)).inspect }
puts rs

# held already: an Integer operand beside a receiver in a variable
rs = []
3.times { |i| rs << r.coerce(i).inspect }
puts rs
