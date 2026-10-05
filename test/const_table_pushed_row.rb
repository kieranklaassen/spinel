# A row pushed onto a constant table of Integer rows is read back by index as
# the row it is.

D1 = [[1, 2], [3, 4]]
D1 << []
p D1[2], D1[2].size, D1[0][1]

D2 = [[1, 2], [3, 4]]
D2 << ["a"]
D2.push([1.5])
p D2[2], D2[2].size, D2[3], D2[0].sum

D3 = [[1, 2], [3, 4]]
D3.unshift(["a", "b"])
D3.insert(1, [])
D3.concat([[], [5]])
p D3[0], D3[1], D3[2][1] + 1, D3[4], D3[5]

D4 = [[1, 2], [3, 4]]
D4.map! { [] }
p D4[0], D4[0].size

D5 = [[1, 2], [3, 4]]
D5.fill(["x"])
p D5[1], D5[1].size

D6 = [[1, 2], [3, 4]]
D6.replace([["a"], [1.5]])
p D6[0], D6[1]

# Integer rows pushed leave a table of Integer rows
D7 = [[1, 2], [3, 4]]
D7 << [5, 6]
D7.push([7])
D7.insert(0, [8, 9])
D7.concat([[10]])
p D7[3], D7[4][0] + D7[3][1], D7[0].sum, D7[5]

# and so do Integer rows that fill it or replace it
D8 = [[1, 2], [3, 4]]
D8.fill([7, 8])
p D8[1], D8[0][1] + 1
D8.replace([[2, 1], [4, 3], [5]])
p D8[2], D8[0].sum, D8.size

# a table whose literal has no Integer row is not made a table of Integer
# rows by what is pushed onto it: its other rows are nil, or not there
E1 = []
E1 << [7, 8]
p E1[0], E1[1].to_a, E1[0][1] + 1

E2 = [nil, nil, nil]
E2.push([7, 8])
E2.append([9])
p E2[0].to_a, E2[3], E2[4], E2[1].nil?

E3 = [nil, nil]
E3.unshift([7, 8])
E3.prepend([5])
case E3[2]
when nil then puts "nil"
when Array then puts "array"
end
begin
  p E3[3].size
rescue NoMethodError
  puts "no size"
end

E4 = [nil, nil]
E4.insert(1, [7, 8])
E4.concat([[9]])
p E4, E4[0].to_a, E4[3], E4[5].to_a

E5 = [nil, nil, nil]
E5.fill([7, 8], 1)
p E5[0].to_a, E5[2]

E6 = []
E6.replace([[7, 8]])
p E6[0], E6[1].to_a
