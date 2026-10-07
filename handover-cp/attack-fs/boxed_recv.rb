xs = [1, 2, 3]
row = [xs, "pad"]
n = [2.0, :pad][0]
p row[0].include?(n)
p row[0].index(n)
ys = [1.0, 2.0, 3.0]
m = [2, :pad][0]
p ys.include?(m), ys.index(m)
p ys.include?(n), ys.index(n)
