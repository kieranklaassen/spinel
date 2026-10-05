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

# a table whose literal has no Integer row is not made a table of Integer
# rows by such a store: its other rows are nil, or not there
T7 = [nil, nil, nil]
T7[1] ||= [7, 8]
p T7[0].to_a, T7[1], T7[2].nil?

T8 = []
T8[1] ||= [7, 8]
case T8[0]
when nil then puts "nil"
when Array then puts "array"
end
begin
  p T8[2].size
rescue NoMethodError
  puts "no size"
end

T9 = [nil, nil]
T9[0] &&= [7, 8]
p T9[0].to_a, T9
