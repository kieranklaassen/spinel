# A table row that is a local holding an empty container is built boxed, as
# the empty literal is, so the table is not a table of Integer Arrays.

e1 = {}
T1 = [[1, 2], e1, [3]]
p T1[1], T1[1].size, T1

e2 = []
T2 = [[1, 2], e2, [3]]
p T2[1], T2[1].size, T2[0].size
T2[1] << 5
p e2, T2

T3 = [[1, 2], [3, 4]]
e3 = []
T3[1] = e3
p T3[1], T3[1].size, T3

e4 = Array.new
T4 = [[1, 2], e4].freeze
p T4[1], T4[1].empty?
T4.each { |a, b| p [a, b] }

class Rows
  def initialize
    e = []
    @rows = [[1, 2], e, [3]]
  end

  def show
    p @rows.inspect
    p @rows[1], @rows[1].size
    @rows.each { |a, b| p [a, b] }
  end
end
Rows.new.show

# a local that is filled is the row it was
f1 = []
f1 << 5
U1 = [[1, 2], f1, [3]]
p U1[1], U1[1].size, U1[1][0] + 1

f2 = []
U2 = [[1, 2], f2, [3]]
f2 << 6
p U2[1], U2[1].size
