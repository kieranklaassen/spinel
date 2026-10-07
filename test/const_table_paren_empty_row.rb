# An empty row written in parentheses is the same empty row.

T1 = [[1, 2], ([]), [3]]
p T1[1], T1[1].size, T1
T1[1] << 5
p T1

T2 = [[1, 2], [3, 4]]
T2[1] = ([])
p T2[1], T2[1].size, T2

T3 = [(Array.new), [1, 2]]
p T3[0], T3[0].empty?
T3.each { |a, b| p [a, b] }

[[1, 2], ([]), [3, 4]].each { |a, b| p [a, b] }
[(({})), [1.5, 2.5]].each { |a, b| p [a, b] }
p [[1, 2], ([])].map { |a, b| [b, a] }

# a row in parentheses that is not empty
T4 = [[1, 2], ([9]), [3]]
p T4[1], T4[1].size, T4[1][0] + 1
