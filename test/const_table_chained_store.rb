# A row stored through a chain of stores into a constant table of Integer rows
# is read back by index as the row it is.

D1 = [[1, 2], [3, 4]]
D1.push([5]).push(["a"])
p D1[3], D1[3].size, D1[2], D1[0][1]

D2 = [[1, 2], [3, 4]]
(D2 << [5]) << []
p D2[3], D2[3].size

D3 = [[1, 2], [3, 4]]
D3 << [5] << [1.5] << {}
p D3[3], D3[4], D3[2].sum

D4 = [[1, 2], [3, 4]]
D4.concat([[5]]).unshift(["a", "b"]).insert(1, [])
p D4[0], D4[1], D4[2][1] + 1, D4[4]

D5 = [[1, 2], [3, 4]]
D5.fill([7, 8]).push(["x"])
p D5[2], D5[2].size, D5[0]

D6 = [[1, 2], [3, 4]]
D6.each { |r| r }.push([:s])
p D6[2], D6.at(2)

D7 = [[1, 2], [3, 4]]
D7.push([5]).replace([["a"], [1.5]])
p D7[0], D7[1]

# a chain of Integer rows leaves a table of Integer rows
D8 = [[1, 2], [3, 4]]
D8.push([5, 6]).push([7]).unshift([8, 9])
p D8[3], D8[4][0] + D8[3][1], D8[0].sum

# the call ahead is any that answers its receiver
D9 = [[3, 4], [1, 2]]
D9.sort!.push(["a"])
D9.reverse!.unshift([1.5])
p D9[0], D9[1], D9[3]

D10 = [[1, 2], [3, 4]]
D10.tap { |t| t.size }.push([])
p D10[2], D10[2].size
D10.select! { |r| r.size > 1 }.push({})
p D10[2], D10[1]

D11 = [[1, 2], [3, 4]]
D11.clear.push(["x"], [5])
p D11[0], D11[1], D11.size

# a chain onto a table whose literal has no Integer row leaves it a general
# table: its other rows are nil, or not there
E1 = [nil, nil]
E1.push([5]).push([7, 8])
p E1[0].to_a, E1[3]

E2 = []
E2.sort!.push([7, 8])
p E2[0], E2[1].to_a

E3 = [nil, nil]
E3.push(nil)[0] = [7, 8]
p E3[1].to_a, E3[0], E3[2].nil?
