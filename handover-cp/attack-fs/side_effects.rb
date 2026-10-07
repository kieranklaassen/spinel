$log = []
def xs = ($log << :recv; [1, 2, 3])
def nd(v) = ($log << :needle; v)
row = [2.0, "x", nil]
p xs.include?(nd(row[0]))
p xs.index(nd(row[1]))
p xs.rindex(nd(row[2]))
p $log
