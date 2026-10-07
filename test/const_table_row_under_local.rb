# A row of a constant's table held under a local is that row, not a copy:
# given an element that is no Integer through the local, the table's row
# has it too. The table read its rows as Integer Arrays, and the local was
# a converted copy of the row.

T1 = [[1, 2], [3, 4]]
e1 = T1[1]
e1 << "s"
p e1, T1[1], T1

T2 = [[1, 2], [3, 4]]
e2 = T2.last
e2.push("s")
p e2, T2[1]

T3 = [[1, 2], [3, 4]]
e3 = T3[0]
e3[0] = "s"
p e3, T3[0], T3[1]

T4 = [[1, 2], [3, 4]]
e4 = T4.first
e4.unshift("s")
p e4, T4[0]

T5 = [[1, 2], [3, 4]]
e5 = T5[1]
e5.concat(["s"])
p e5, T5[1]

T6 = [[1, 2], [3, 4]]
e6 = T6[1]
e6 << 1.5
p e6, T6[1]

T7 = [[1, 2], [3, 4]]
e7 = T7[1]
e7 << nil
p e7, T7[1]

T8 = [[1, 2], [3, 4]]
e8 = T8[1]
e8.insert(1, :s)
p e8, T8[1]

# in a method, in a block, and a class's constant
T9 = [[1, 2], [3, 4]]
def row_in_method
  e = T9[1]
  e << "s"
  p e, T9[1]
end
row_in_method

T10 = [[1, 2], [3, 4]]
e10 = T10[1]
[1, 2].each { |i| e10 << i.to_s }
p e10, T10[1]

class Grid
  ROWS = [[1, 2], [3, 4]]
  def mark
    e = ROWS[0]
    e << :x
    p e, ROWS[0], ROWS
  end
end
Grid.new.mark

# the table's other reads
T11 = [[1, 2], [3, 4], [5, 6]]
e11 = T11[1]
e11 << "s"
p e11.equal?(T11[1])
p T11[0].sum, T11[0][1] * 2, T11.map { |r| r.size }
T11.each { |a, b| p [a, b] }
x11, y11 = T11[2]
p x11 + y11

# a store that never runs
T12 = [[1, 2], [3, 4]]
e12 = T12[1]
e12 << "s" if e12.size > 5
p e12, T12[1], T12[0][0] + T12[1][1]

# an Integer keeps the row an Integer Array, and a copy stays a copy
T13 = [[1, 2], [3, 4]]
e13 = T13[1]
e13 << 9
p e13, T13[1], T13[1].sum

T14 = [[1, 2], [3, 4]]
e14 = T14[1].dup
e14 << "s"
p e14, T14[1]

# a value of two kinds is no evidence: the local is as it was
T15 = [[1, 2], [3, 4]]
e15 = T15[1]
e15 << (e15.size > 1 ? "s" : 1)
p e15
