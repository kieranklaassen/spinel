# An empty `{}` and a bare `Array.new` stored into a table of rows are no
# rows of the table's kind: the table stays boxed and every element reads
# back as what it is.

t = [[1, 2], [3, 4]]
t << {}
p t[2]
p t.size
t.each { |r| p r.size }

u = [[1, 2]]
u.push({})
p u[1]

v = [[1, 2]]
v[1] = {}
p v[1]

# a bare Array.new
w = [[1, 2], [3, 4]]
w << Array.new
p w[2].size
w.last << 5
w.each { |r| p r }
p w.map(&:sum)

x = [[1, 2]]
x[1] = Array.new
p x[1].size
p x

# Float rows
f = [[1.5, 2.5]]
f << {}
p f[1]
f.each { |r| p r.size }

# a table of objects
class K
  def initialize(n) = @n = n
  def n = @n
end
o = [K.new(1), K.new(2)]
o << {}
p o[2]
p o[0].n
q = [K.new(1)]
q << Array.new
p q[1].size
p q[1]

# through a method's result
def rows = [[1, 2], [3]]
m = rows
m << {}
p m.last
p m.map(&:size)

# the empty literal still joins the table as a row of its kind
z = [[1, 2]]
z << []
z[1] << 7
p z
p z[1].sum
