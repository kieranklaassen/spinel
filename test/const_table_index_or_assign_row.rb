# `T[i] ||= v` and `T[i] &&= v` store a row as `T[i] = v` does.

T1 = [[1, 2], nil, [3]]
T1[1] ||= []
p T1[1], T1[1].size, T1

T2 = [[1, 2], nil, [3]]
T2[1] ||= ["a"]
p T2[1], T2[1].size, T2

T3 = [[1, 2], [5], [3]]
T3[1] &&= []
p T3[1], T3

T4 = [[1, 2], nil]
i = 1
T4[i] ||= {}
p T4[1], T4

T5 = [[1, 2], nil, [3]]
p(T5[1] ||= [1.5])
p T5

# an Integer row stored the same way stays one
T6 = [[1, 2], nil, [3]]
T6[1] ||= [7]
T6[0] &&= [8, 9]
p T6[1], T6[0], T6[1][0] + T6[0][1], T6
