# A Symbol read out of a mixed Array answers `[]` with an Integer as its
# name does: the character there, nil out of range. It answered nil.
x = [:zed, 1][0]
p x[0], x[1], x[2]
p x[-1], x[-3]
p x[3], x[-4], x[9]
i = 1
p x[i], x[i - 2]
p x[0] + x[2]
p x[0].frozen?
p x.slice(0), x.slice(-1), x.slice(9)

# the same Symbol in a typed local, and a String read out of the Array
y = :zed
p y[0], y[-1], y[9]
z = ["zed", 1][0]
p z[0], z[-1], z[9]

# one character, a name with a space, a name of two bytes a character
p [:q, 1][0][0], [:q, 1][0][1]
p [:"a b", 1][0][1]
p [:"é!", 1][0][0], [:"é!", 1][0][-1]

# each element of the mixed Array, by what it is
[:sym, "str", 5].each { |v| p v[0] }

# a method that answers a Symbol or a String
def pick(n) = n > 0 ? :name : "text"
p pick(1)[0], pick(0)[0]

# a Symbol out of a Hash's values
h = { a: :first, b: 2 }
p h[:a][0], h[:a][-1]
