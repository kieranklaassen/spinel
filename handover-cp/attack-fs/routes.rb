xs = [1, 2, 3, 2]
row = [2.0, 5.0, "x"]
n = row[0]
p xs.include?(n) ? "yes" : "no"
puts "found" if xs.member?(n)
i = xs.index(n)
p i
p xs.index(n) + 10
p xs.rindex(n).to_s
p [xs.find_index(n), xs.index(row[1]), xs.index(row[2])]
h = { xs.include?(n) => 1 }
p h
p xs.include?(row[0]) && xs.include?(row[1])
p xs.include?(row[0]) || xs.include?(row[2])
def has(a, v) = a.include?(v)
p has(xs, row[0]), has(xs, row[1])
def at(a, v) = a.index(v)
p at(xs, row[0]), at(xs, row[2])
p xs.map { |e| e * 2 }.include?(row[0] * 2)
p xs.select { |e| e > 1 }.index(n)
p (1..5).to_a.include?(n)
p xs.dup.include?(n), xs.reverse.index(n), xs.sort.rindex(n)
